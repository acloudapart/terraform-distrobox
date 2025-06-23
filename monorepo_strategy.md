This document is a guide for our monorepo, detailing the directory structure, inter-account communication, and the necessary GitHub Actions workflows.

-----

### **Document: Monorepo-Based AWS Environment Configuration**

This guide adapts the setup of your `devops`, `dev`, and `prod` accounts for a monorepo structure. It focuses on how to manage the distinct Terraform configurations and orchestrate deployments using path-based triggers in GitHub Actions.

#### **1. Recommended Monorepo Directory Structure**

A clear directory structure is crucial. Organize your repository as follows:

```
/terraform/
│
├── .github/
│   └── workflows/
│       ├── deploy-devops.yml   # Manages the devops account itself
│       ├── deploy-dev.yml      # Deploys to the dev account
│       └── deploy-prod.yml     # Deploys to the prod account
│
├── environments/
│   ├── devops/
│   │   ├── main.tf
│   │   ├── backend.tf          # Configured for the devops state bucket
│   │   └── ssm.tf              # Writes role ARN to SSM
│   │
│   ├── dev/
│   │   ├── main.tf
│   │   ├── backend.tf          # Configured for the dev state bucket
│   │   └── data.tf             # Reads role ARN from SSM
│   │
│   └── prod/
│       ├── main.tf
│       ├── backend.tf          # Configured for the prod state bucket
│       └── data.tf             # Reads role ARN from SSM
│
└── README.md
```

#### **2. Sharing the Role ARN via SSM Parameter Store**

Since your Terraform states are decentralized, you cannot use `terraform_remote_state` to share the ARN of the central IAM role. The best practice is to use the AWS Systems Manager (SSM) Parameter Store.

**A. In your `devops` Terraform code, write the ARN to an SSM Parameter:**

Create a new file `environments/devops/ssm.tf`. This ensures that after the central role is created, its ARN is published to a known location.

```terraform
# environments/devops/ssm.tf

resource "aws_ssm_parameter" "github_central_role_arn" {
  name  = "/global/iam/cicd/GitHubActionsCentralRoleArn"
  type  = "String"
  value = aws_iam_role.github_actions_central_role.arn # From your existing iam.tf
  
  # Overwrite the parameter if the ARN changes
  overwrite = true

  tags = {
    Description = "ARN for the central GitHub Actions role used by CI/CD"
  }
}
```

**B. In your `dev` and `prod` Terraform code, read the ARN using a data source:**

Now, your other environments can look up this value without being directly dependent on the `devops` state file.

Create a file named `environments/dev/data.tf` (and a similar one for `prod`).

```terraform
# environments/dev/data.tf

data "aws_ssm_parameter" "github_central_role_arn" {
  name = "/global/iam/cicd/GitHubActionsCentralRoleArn"
}

# Now you can use the ARN in your trust policy
# This code goes into your IAM role definition for the TerraformExecutionRole
data "aws_iam_policy_document" "terraform_execution_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_ssm_parameter.github_central_role_arn.value]
    }
  }
}
```

This approach decouples your environments, allowing you to apply changes to one without affecting the others.

#### **3. GitHub Actions Workflows for a Monorepo**

Your workflows will use path filters to trigger deployments only when code in a specific environment's directory changes.

**Example Workflow: `/.github/workflows/deploy-dev.yml`**

This workflow will run `terraform apply` for the `dev` environment when changes are pushed to the `environments/dev/` directory on the `main` branch.

```yaml
name: 'Deploy to DEV Environment'

on:
  push:
    branches:
      - main
    paths:
      - 'environments/dev/**'

jobs:
  terraform-dev:
    name: 'Terraform DEV'
    runs-on: ubuntu-latest
    
    # Grant permissions for OIDC
    permissions:
      id-token: write
      contents: read

    steps:
    - name: Checkout Code
      uses: actions/checkout@v4

    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        # 1. First, authenticate to the DEVOPS account to get the central role
        role-to-assume: arn:aws:iam::<DEVOPS_ACCOUNT_ID>:role/GitHubActionsCentralRole
        aws-region: us-east-1 # Your AWS region

    - name: Assume DEV Deployment Role
      uses: aws-actions/configure-aws-credentials@v4
      with:
        # 2. Now, assume the execution role within the target DEV account
        role-to-assume: arn:aws:iam::<DEV_ACCOUNT_ID>:role/TerraformExecutionRole
        aws-region: us-east-1 # Your AWS region
        role-session-name: GitHubActions-DEV-Deploy

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3

    - name: Terraform Init
      id: init
      run: terraform init
      # Set the working directory for all Terraform commands
      working-directory: ./environments/dev

    - name: Terraform Plan
      id: plan
      run: terraform plan -no-color
      working-directory: ./environments/dev

    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' # Only apply on the main branch
      run: terraform apply -auto-approve
      working-directory: ./environments/dev
```

**Key Adaptations for Monorepo:**

1.  **`on.push.paths`**: This trigger ensures the workflow only runs when files inside `environments/dev/` are changed. Create a similar workflow for `prod` that triggers on `environments/prod/**`.
2.  **`working-directory`**: Every Terraform command (`init`, `plan`, `apply`) includes this parameter to specify which environment's configuration to use.
3.  **Two-Step Role Assumption**: The workflow first authenticates to the `devops` account using OIDC to assume the `GitHubActionsCentralRole`. It then immediately uses that role's permissions to assume the `TerraformExecutionRole` in the target `dev` account. All subsequent Terraform commands run with the permissions of the `TerraformExecutionRole`.
4.  **Account IDs**: Remember to replace `<DEVOPS_ACCOUNT_ID>` and `<DEV_ACCOUNT_ID>` with the actual account IDs.

You would create a similar but separate workflow file for your `prod` environment, perhaps triggered by creating a release tag instead of a push to `main` for better control.