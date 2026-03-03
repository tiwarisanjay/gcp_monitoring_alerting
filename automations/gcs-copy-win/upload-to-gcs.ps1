# ==============================
# CONFIG
# ==============================
$SourceFolder      = "C:\incoming"
$ProcessedFolder   = "C:\processed"
$BucketName        = "your-bucket-name"
$LogFile           = "C:\scripts\upload.log"

# Email settings
$SmtpServer = "smtp.office365.com"     # Change if using Gmail or other
$SmtpPort   = 587
$From       = "alerts@yourdomain.com"
$To         = "your@email.com"
$Username   = "alerts@yourdomain.com"
$Password   = "YOUR_EMAIL_PASSWORD"    # Or use App Password

# ==============================
# FUNCTION: Send Failure Email
# ==============================
function Send-FailureEmail($message) {
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

    Send-MailMessage `
        -SmtpServer $SmtpServer `
        -Port $SmtpPort `
        -UseSsl `
        -Credential $Cred `
        -From $From `
        -To $To `
        -Subject "❌ GCS Upload Failed on $env:COMPUTERNAME" `
        -Body $message
}

# ==============================
# MAIN LOGIC
# ==============================

try {
    Add-Content $LogFile "`n==== Run started at $(Get-Date) ===="

    $Files = Get-ChildItem $SourceFolder -File

    foreach ($File in $Files) {

        $FullPath = $File.FullName

        # Check if file is locked
        $maxRetries = 5
        $retryDelay = 5
        $locked = $true

        for ($i=0; $i -lt $maxRetries; $i++) {
            try {
                $stream = [System.IO.File]::Open($FullPath,'Open','ReadWrite','None')
                $stream.Close()
                $locked = $false
                break
            } catch {
                Start-Sleep -Seconds $retryDelay
            }
        }

        if ($locked) {
            throw "File still locked: $FullPath"
        }

        # Move file
        $MovedPath = Join-Path $ProcessedFolder $File.Name
        Move-Item $FullPath $MovedPath -Force

        # Upload to GCS
        $gsutilPath = "C:\Program Files\Google\Cloud SDK\google-cloud-sdk\bin\gsutil.cmd"
        & $gsutilPath cp $MovedPath gs://$BucketName/

        if ($LASTEXITCODE -ne 0) {
            throw "gsutil failed for $MovedPath"
        }

        Add-Content $LogFile "Uploaded successfully: $MovedPath"
    }

    Add-Content $LogFile "Run completed successfully."

}
catch {
    $ErrorMessage = $_.Exception.Message
    Add-Content $LogFile "ERROR: $ErrorMessage"
    Send-FailureEmail $ErrorMessage
    exit 1
}