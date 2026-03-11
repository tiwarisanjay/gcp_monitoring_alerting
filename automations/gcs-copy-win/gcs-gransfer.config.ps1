@{
    sourceFolder    = "C:\incoming"
    processedFolder = "C:\processed"
    bucketName      = "your-bucket-name"
    logFile         = "C:\scripts\gcs-gransfer.log"
    lockFile        = "C:\scripts\gcs-gransfer.lock"
    pgpkey          = "keys/public-key.asc" # Can be full gs:// path or object path in bucketName
    pgpLocalFolder  = "C:\scripts\pgp"
    gpgPath         = "C:\Program Files (x86)\GnuPG\bin\gpg.exe"
    gsutilPath      = "C:\Program Files\Google\Cloud SDK\google-cloud-sdk\bin\gsutil.cmd"
}
