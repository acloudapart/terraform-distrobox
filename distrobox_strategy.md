# Terraform Distrobox Project

This project provides a structured and scalable way to manage your AWS infrastructure using Terraform, with support for multiple environments and AWS SSO authentication.

## 1\. Project Structure

The project is organized into the following directories:

* `environments/`: Contains the configurations for each of your environments (e.g., `dev`, `prod`). Each environment has its own state file to ensure isolation.
* `modules/`: Contains reusable, private Terraform modules that enforce your company's specific standards.
* `provision.sh`: A script to set up the `distrobox` container with the necessary tools.

## 2\. Getting Started

### 2.1. Create the Distrobox Container

To get started, create the `distrobox` container that will be used for running Terraform:

```bash
distrobox create --name terraform --image ubuntu:24.04 --init-hooks "bash $HOME/devops/terraform-distrobox/provision.sh"
```

### 2.2. Configure AWS SSO

This project is configured to use AWS SSO for authentication. To set this up, you need to configure your AWS CLI with your SSO details.

1. **Configure your AWS profile:**
   
   ```bash
   aws configure sso --profile a-cloud-apart-co
   ```
   
   Follow the prompts to enter your SSO start URL and the SSO region.

2. **Login to your AWS account:**
   
   ```bash
   aws sso login --profile a-cloud-apart-co
   ```

### 2.3. Set up Remote State Storage

This project uses an S3 bucket for remote state storage. You will need to create the following resources in your AWS account:

1. **An S3 bucket** to store the Terraform state files.
2. **A DynamoDB table** for state locking to prevent concurrent modifications.

Once you have created these resources, update the `backend.tf` files in the `environments/dev` and `environments/prod` directories with the names of your S3 bucket and DynamoDB table.

## 3\. Workflow

### 3.1. Working with Environments

To work with a specific environment, navigate to the corresponding directory:

```bash
cd environments/dev
```

### 3.2. Initializing Terraform

Before you can run Terraform, you need to initialize the backend:

```bash
terraform init
```

### 3.3. Planning and Applying Changes

Once Terraform is initialized, you can use the standard `plan` and `apply` commands to manage your infrastructure:

```bash
terraform plan
terraform apply
```
