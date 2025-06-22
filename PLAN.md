# Plan: Multi-Environment AWS SSO Terraform Project

This document outlines the plan for structuring a Terraform project to manage AWS resources for multiple environments (`dev` and `prod`) using AWS SSO for authentication.

## 1. Directory Structure for Environments and Modules

We will create a new directory structure to manage the Terraform code effectively:

*   `environments/`: This directory will contain subdirectories for each environment (`dev` and `prod`). This approach isolates the state files for each environment, which is critical for preventing changes in one environment from accidentally impacting another.
*   `modules/`: This directory will house reusable infrastructure components. For example, if you have a standard S3 bucket configuration, you can define it once in a module and reuse it in both `dev` and `prod`.
*   `providers.tf`: A new root-level file to define the AWS provider configuration, ensuring consistency across all environments.

## 2. AWS Provider Configuration with SSO

The root `providers.tf` file will configure the AWS provider to use AWS SSO for authentication. It will look like this:

```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # You can change this to your desired region
  sso {
    session_name = "A-Cloud-Apart-co"
  }
}
```

**Note:** This configuration relies on your local AWS CLI being configured for SSO. Instructions for this will be added to the `README.md`.

## 3. Environment-Specific Configurations

Each environment subdirectory (e.g., `environments/dev/`) will contain:

*   `main.tf`: The main configuration file for the environment, which will call the reusable modules.
*   `backend.tf`: A file to configure remote state storage using an S3 bucket. This is crucial for collaboration and state management.
*   `variables.tf` and `outputs.tf`: For environment-specific inputs and outputs.

## 4. Update .gitignore and README.md

*   We will create a `.gitignore` file to exclude Terraform state and temporary files from version control.
*   The `README.md` will be significantly updated to explain the new project structure, how to set up AWS SSO with the AWS CLI, and the workflow for deploying changes to each environment.

## 5. Proposed Project Structure Diagram

```mermaid
graph TD
    subgraph "Proposed Project Structure for AWS SSO"
        A["terraform-distrobox/"]
        A --> B("provision.sh")
        A --> C("README.md (Updated)")
        A --> D(".gitignore")
        A --> P("providers.tf (Root Provider Config)")
        A --> E("environments/")
        A --> J("modules/")

        subgraph "environments/"
            direction TB
            E --> F("dev/")
            E --> G("prod/")
        end

        subgraph "dev/"
            direction TB
            F --> F1("main.tf")
            F --> F2("backend.tf")
        end

        subgraph "prod/"
            direction TB
            G --> G1("main.tf")
            G --> G2("backend.tf")
        end

        subgraph "modules/"
            direction TB
            J --> K("example_s3_bucket/")
            subgraph "example_s3_bucket/"
                K --> L("main.tf")
                K --> M("variables.tf")
                K --> N("outputs.tf")
            end
        end
    end