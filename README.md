# Terraform Monitoring Alerting Walkthrough

I have set up the Terraform project structure with `nonprod`, `uat`, and `prod` environments, all using a shared `logging_alert` module.

## Created Structure
```text
.
├── modules
│   └── logging_alert
│       ├── main.tf       # Alert policy and notification channel
│       ├── variables.tf  # Input variables
│       └── outputs.tf    # Output values
├── nonprod
│   ├── config.tf         # GCS backend configuration
│   └── main.tf           # Environment configuration
├── uat
│   ├── config.tf         # GCS backend configuration
│   └── main.tf           # Environment configuration
└── prod
    ├── config.tf         # GCS backend configuration
    └── main.tf           # Environment configuration
```

## Module Details
The `logging_alert` module creates:
- An **Email Notification Channel** for `sanjay.tiwari@gmail.com`.
- An **Alert Policy** that triggers when logging byte writes to `_default` bucket exceed **50MB** in **5 minutes**.

## Remote Backend
State is stored in GCS bucket `tf-state-bucket` with the following prefixes:
- Non-prod: `terraform/state/nonprod`
- UAT: `terraform/state/uat`
- Prod: `terraform/state/prod`

## Version Control
- **Git initialized**: Repository initialized locally.
- **Commit made**: "Initial commit: Terraform monitoring alerting setup" (GPG signing enabled).
- **Remote**: Configured as `https://github.com/tiwarisanjay/gcp_monitoring_alerting.git`.
- **Push Status**: Pending.

## Verification Steps (Non-Prod)
Use these commands to test the `nonprod` environment:

1.  **Navigate to nonprod**:
    ```sh
    cd nonprod
    ```
2.  **Initialize Terraform**:
    This will download the provider plugins and configure the GCS backend.
    ```sh
    terraform init
    ```
3.  **Validate Configuration**:
    Checks the syntax and structure.
    ```sh
    terraform validate
    ```
4.  **Preview Changes**:
    Shows what resources will be created.
    ```sh
    terraform plan
    ```
5.  **Apply Changes**:
    Creates the resources in GCP.
    ```sh
    terraform apply
    ```

## Notes
- Ensure the project `sanjay_test_project_0001` exists and you have permissions to create monitoring resources.
- The state is currently stored locally (default). For a production setup, consider configuring a remote backend (e.g., GCS bucket).
