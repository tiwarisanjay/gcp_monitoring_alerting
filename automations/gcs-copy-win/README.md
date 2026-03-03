Windows Server → Google Cloud Storage (GCS) Automated Upload
Overview

This guide sets up:

File monitoring from C:\incoming

Safe file move (only if not locked)

Upload to GCS bucket

Logging

Email notification on failure

Scheduled execution via Task Scheduler

This is designed for quick automation but built in a production-safe way.

1️⃣ Prerequisites
Install Google Cloud SDK

Download and install:

https://cloud.google.com/sdk/docs/install

After install, verify:

gcloud --version
gsutil --version
Authenticate with Service Account (Recommended)

Create Service Account in GCP

Grant it:

Storage Object Admin (or minimum required)

Download JSON key

Authenticate:

gcloud auth activate-service-account --key-file="C:\keys\service-account.json"

Test:

gsutil ls gs://your-bucket-name
2️⃣ Folder Structure (Required)

Create:

C:\incoming
C:\processed
C:\scripts
3️⃣ Create the Script

Save this as:

C:\scripts\upload-to-gcs.ps1 

What You MUST Update in Script

Update these values:

Required
$BucketName
$From
$To
$Username
$Password
If NOT Using Office365

Change:

$SmtpServer
$SmtpPort

Examples:

Provider	SMTP Server	Port
Gmail	smtp.gmail.com	587
O365	smtp.office365.com	587
Internal SMTP	your.smtp.local	25
5️⃣ (Recommended) Secure Email Password

Instead of storing plaintext password:

Run once:

Get-Credential | Export-Clixml "C:\scripts\smtpcred.xml"

Then replace email credential section with:

$Cred = Import-Clixml "C:\scripts\smtpcred.xml"

Remove $Password variable.

6️⃣ Test Script Manually

Run:

cd C:\scripts
.\upload-to-gcs.ps1

Check:

C:\scripts\upload.log
7️⃣ Schedule Task (Windows Cron Equivalent)

Open:

taskschd.msc

Create Task → Configure:

General

Run whether user logged in or not

Run with highest privileges

Trigger

Repeat every 5 minutes

Duration: Indefinitely

Action

Program:

powershell.exe

Arguments:

-ExecutionPolicy Bypass -File "C:\scripts\upload-to-gcs.ps1"

Start In:

C:\scripts

Save.

8️⃣ Test Scheduled Task

Run manually:

schtasks /run /tn "YourTaskName"

Check status:

schtasks /query /tn "YourTaskName" /v /fo list
9️⃣ How It Works
Step	Action
1	Scans C:\incoming
2	Checks file lock
3	Moves file to C:\processed
4	Uploads to GCS
5	Logs success
6	Sends email if failure