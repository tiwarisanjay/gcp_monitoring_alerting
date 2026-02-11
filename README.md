# Terraform Monitoring Alerting

This project sets up monitoring and alerting in Google Cloud Platform (GCP) using Terraform. It includes three environments: `nonprod`, `uat`, and `prod`, all utilizing a shared local module for consistent alert policies.

## Project Structure
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

## Module: logging_alert
The shared module `modules/logging_alert` provisions:
- **Notification Channels**: Supports Email and PagerDuty. At least one must be provided.
- **Alert Policy**: Triggers when logging byte writes to the `_default` bucket exceed a specified threshold.

### Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_id` | GCP Project ID | string | n/a | yes |
| `email_address` | Email address for notifications | string | `null` | no* |
| `pagerduty_service_key` | PagerDuty service key | string | `null` | no* |
| `threshold_mb` | Alert threshold in MB | number | `50` | no |

*\* Either `email_address` or `pagerduty_service_key` must be provided.*

## Remote Backend
Terraform state is stored in the GCS bucket `tf-state-bucket` with the following prefixes:
- **Non-prod**: `terraform/state/nonprod`
- **UAT**: `terraform/state/uat`
- **Prod**: `terraform/state/prod`

## Version Control
- **Repository**: `https://github.com/tiwarisanjay/gcp_monitoring_alerting.git`

## Usage (Non-Prod)
To deploy changes to the `nonprod` environment:

1.  **Navigate to the environment directory**:
    ```sh
    cd nonprod
    ```
2.  **Initialize Terraform**:
    Downloads provider plugins and configures the GCS backend.
    ```sh
    terraform init
    ```
3.  **Validate Configuration**:
    Checks for syntax errors.
    ```sh
    terraform validate
    ```
4.  **Plan Changes**:
    Previews the resources to be created or modified.
    ```sh
    terraform plan
    ```
5.  **Apply Changes**:
    Applies the configuration to GCP.
    ```sh
    terraform apply
    ```

## Prerequisites
- **GCP Project**: `sanjay_test_project_0001` must exist.
- **Permissions**: The Executor must have permissions to manage Monitoring resources and access the GCS state bucket.
- **Terraform**: Terraform must be installed locally.
