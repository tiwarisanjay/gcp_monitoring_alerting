$ErrorActionPreference = "Stop"

# ==============================
# CONFIG
# ==============================
$sourceFolder    = "C:\incoming"
$processedFolder = "C:\processed"
$bucketName      = "your-bucket-name"
$logFile         = "C:\scripts\gcs-gransfer.log"
$lockFile        = "C:\scripts\gcs-gransfer.lock"
$pgpkey          = "keys/public-key.asc" # Can be full gs:// path or object path within $bucketName
$pgpLocalFolder  = "C:\scripts\pgp"
$gpgPath         = "C:\Program Files (x86)\GnuPG\bin\gpg.exe"

# Optional: override if gsutil is in a different location.
$gsutilPath      = "C:\Program Files\Google\Cloud SDK\google-cloud-sdk\bin\gsutil.cmd"

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")][string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp [$Level] $Message"
}

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

function Ensure-CommandPath {
    param([Parameter(Mandatory = $true)][string]$PathToCheck, [Parameter(Mandatory = $true)][string]$Name)
    if (-not (Test-Path -Path $PathToCheck)) {
        throw "$Name not found at path: $PathToCheck"
    }
}

function Test-FileStable {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [int]$Checks = 3,
        [int]$DelaySeconds = 5
    )

    for ($i = 0; $i -lt $Checks; $i++) {
        if (-not (Test-Path -Path $FilePath)) {
            return $false
        }

        $itemBefore = Get-Item -LiteralPath $FilePath
        $sizeBefore = $itemBefore.Length
        $timeBefore = $itemBefore.LastWriteTimeUtc

        Start-Sleep -Seconds $DelaySeconds

        if (-not (Test-Path -Path $FilePath)) {
            return $false
        }

        $itemAfter = Get-Item -LiteralPath $FilePath
        if ($itemAfter.Length -ne $sizeBefore -or $itemAfter.LastWriteTimeUtc -ne $timeBefore) {
            return $false
        }
    }

    try {
        $stream = [System.IO.File]::Open($FilePath, "Open", "ReadWrite", "None")
        $stream.Close()
        return $true
    } catch {
        return $false
    }
}

function Get-PgpKeyGsPath {
    param(
        [Parameter(Mandatory = $true)][string]$Bucket,
        [Parameter(Mandatory = $true)][string]$PgpKeyValue
    )

    if ($PgpKeyValue -like "gs://*") {
        return $PgpKeyValue
    }

    $trimmed = $PgpKeyValue.TrimStart("/")
    return "gs://$Bucket/$trimmed"
}

function Run-ExternalCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$FailureMessage (exit code $LASTEXITCODE)"
    }
}

Ensure-Directory -Path (Split-Path -Path $logFile -Parent)
Write-Log -Message "==== Run started ===="

if (Test-Path -Path $lockFile) {
    Write-Log -Message "Lock file exists. Aborting run: $lockFile" -Level "WARN"
    exit 1
}

try {
    New-Item -Path $lockFile -ItemType File -Force | Out-Null
    Write-Log -Message "Lock file created: $lockFile"

    Ensure-Directory -Path $sourceFolder
    Ensure-Directory -Path $processedFolder
    Ensure-Directory -Path $pgpLocalFolder

    Ensure-CommandPath -PathToCheck $gsutilPath -Name "gsutil"
    Ensure-CommandPath -PathToCheck $gpgPath -Name "gpg"

    $keyGsPath = Get-PgpKeyGsPath -Bucket $bucketName -PgpKeyValue $pgpkey
    $keyFileName = [System.IO.Path]::GetFileName($keyGsPath)
    if ([string]::IsNullOrWhiteSpace($keyFileName)) {
        throw "Unable to determine key filename from pgpkey value: $pgpkey"
    }

    $localKeyPath = Join-Path -Path $pgpLocalFolder -ChildPath $keyFileName
    if (Test-Path -Path $localKeyPath) {
        Write-Log -Message "PGP public key already exists locally. Skipping download: $localKeyPath"
    } else {
        Write-Log -Message "Downloading PGP public key from $keyGsPath to $localKeyPath"
        Run-ExternalCommand `
            -Executable $gsutilPath `
            -Arguments @("cp", $keyGsPath, $localKeyPath) `
            -FailureMessage "Failed to download PGP key from GCS"
    }

    Write-Log -Message "Importing PGP key from $localKeyPath"
    Run-ExternalCommand `
        -Executable $gpgPath `
        -Arguments @("--batch", "--yes", "--import", $localKeyPath) `
        -FailureMessage "Failed to import PGP key"

    $files = Get-ChildItem -Path $sourceFolder -File | Sort-Object LastWriteTime
    if (-not $files) {
        Write-Log -Message "No files found in source folder: $sourceFolder"
        exit 0
    }

    $failureCount = 0

    foreach ($file in $files) {
        $originalPath = $file.FullName
        Write-Log -Message "Processing file: $originalPath"

        try {
            if (-not (Test-FileStable -FilePath $originalPath)) {
                throw "File appears to still be changing or locked: $originalPath"
            }

            $movedPath = Join-Path -Path $processedFolder -ChildPath $file.Name
            Move-Item -LiteralPath $originalPath -Destination $movedPath -Force
            Write-Log -Message "Moved file to processed folder: $movedPath"

            $encryptedPath = "$movedPath.gpg"

            Run-ExternalCommand `
                -Executable $gpgPath `
                -Arguments @("--batch", "--yes", "--trust-model", "always", "--output", $encryptedPath, "--encrypt", "--recipient-file", $localKeyPath, $movedPath) `
                -FailureMessage "GPG encryption failed for file $movedPath"

            Write-Log -Message "Encrypted file created: $encryptedPath"

            Run-ExternalCommand `
                -Executable $gsutilPath `
                -Arguments @("cp", $encryptedPath, "gs://$bucketName/") `
                -FailureMessage "GCS upload failed for encrypted file $encryptedPath"

            Write-Log -Message "Uploaded encrypted file to gs://$bucketName/: $encryptedPath"
        } catch {
            $failureCount++
            Write-Log -Message "Failed processing $originalPath. Error: $($_.Exception.Message)" -Level "ERROR"
        }
    }

    if ($failureCount -gt 0) {
        throw "Run completed with $failureCount failed file(s)."
    }

    Write-Log -Message "Run completed successfully."
} catch {
    Write-Log -Message "Script failed: $($_.Exception.Message)" -Level "ERROR"
    exit 1
} finally {
    if (Test-Path -Path $lockFile) {
        Remove-Item -Path $lockFile -Force -ErrorAction SilentlyContinue
        Write-Log -Message "Lock file removed: $lockFile"
    }
    Write-Log -Message "==== Run ended ===="
}
