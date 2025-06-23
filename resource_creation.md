# Standard Process for Provisioning AWS Resources with Terraform

This document outlines the standard methodology for creating, managing, and updating any AWS resource within this project. The process is designed to be scalable, maintainable, and to enforce security, reliability, and cost-management best practices consistently across all environments.

Our approach is founded on a **Hybrid Configuration-Driven Module Pattern**. The core principle is to get the "best of both worlds": we leverage well-maintained, feature-rich **public modules** for resource creation while wrapping them in **private modules** to enforce our specific standards and simplify configuration.

## Core Principles

1. **Public Modules (The "Engine"):** For complex resources like a VPC or an EKS cluster, we use a well-vetted, popular public module from the Terraform Registry. This provides a robust and community-tested foundation, saving us from reinventing the wheel.

2. **Private Wrapper Modules (The "Guardrails"):** We create our own simple, private modules in the `modules/` directory. These modules *call* the public modules. The purpose of our private wrapper is to set opinionated, secure defaults for our organization. For example, it can enforce tagging, disable dangerous configurations, and apply specific security settings by default. This is how we ensure every resource adheres to our baseline.

3. **Configuration as Data (The "What"):** We define the resources that should exist in a simple map within a `locals.tf` file for each environment and resource type. This file acts as a central registry, making it easy to see at a glance what is deployed. Adding or modifying a resource is as simple as changing an entry in this map.

4. **Dynamic Instantiation (The "Factory"):** A `for_each` meta-argument in a `.tf` file reads the data from `locals.tf` and calls our **private wrapper module** for each item. This loop is the factory that builds resources according to our specifications.

## Directory Structure

Our configurations are organized by environment and resource type. The key change is that our private modules act as wrappers that call public modules.

```
terraform/
├── modules/
│   └── s3-bucket/         <-- Our private wrapper module.
│       ├── main.tf               <-- Calls the public module and applies our standards.
│       ├── variables.tf
│       └── versions.tf           <-- Pins the version of the public module.
└── env/
    ├── dev/
    │   └── s3-resources/         <-- Terraform config for DEV S3 buckets.
    │       ├── locals.tf
    │       └── buckets.tf
    ├── prod/
    │   └── s3-resources/         <-- Terraform config for PROD S3 buckets.
    │       ├── locals.tf
    │       └── buckets.tf
    └── devops/
        └── s3-resources/         <-- Terraform config for DEVOPS S3 buckets.
            ├── locals.tf
            └── buckets.tf
```

## How to Provision a New Resource: Step-by-Step

The process remains simple and declarative, typically requiring modification of only one file.

### Step 1: Navigate to the Target Directory

Open your terminal and change into the directory for the correct environment and resource type.

```bash
# Example for a new S3 bucket in the DEV environment
cd env/dev/s3-resources
```

### Step 2: Define Your Resource in `locals.tf`

Open the `locals.tf` file. This file contains the maps that serve as the central registry for all resources of this type. Add a new entry for your resource. The **key** of the map entry will be part of the resource's name, and the **value** is a map used to override any defaults exposed by our private wrapper module.

```hcl
# env/prod/s3-resources/locals.tf

locals {
  app_data_buckets = {
    "billing-uploads"  = {} // An existing bucket, using our wrapper's defaults.
    "customer-reports" = {} // An existing bucket, using our wrapper's defaults.
    "project-assets"   = {   // A bucket with an overridden setting.
      versioning = false // This value is passed to our private module.
    }
  }

  // Add your new bucket to the appropriate map
  logging_buckets = {
    "elb-access-logs"   = {}
    "new-app-flow-logs" = {} // <-- ADD YOUR NEW BUCKET HERE
  }
}
```

### Step 3: Ensure the Category Instantiation Exists

The files named `buckets.tf`, `vpcs.tf`, etc., contain the `module` blocks that read from the maps in `locals.tf`. These blocks call our **private wrapper module**.

* **If you added your resource to an existing category** (like `logging_buckets` in the example), the corresponding `module` block already exists, and you don't need to do anything else.

* **If you are creating a new category of resources**, you will copy a standard `module` block that calls the appropriate private wrapper.

Here is an example of what the instantiation file (`buckets.tf`) looks like. Note how it calls our `s3-bucket` wrapper, not the public module directly.

```hcl
# env/prod/s3-resources/buckets.tf

# Instantiates the logging buckets defined in locals.tf
module "logging_buckets" {
  # Call our private wrapper module
  source   = "../../../modules/s3-bucket"

  # Iterate over the map from locals.tf
  for_each = local.logging_buckets

  # ----- REQUIRED MODULE INPUTS -----
  # Construct the bucket name from the map key
  bucket_name = "my-company-logs-${each.key}"

  # Pass through any optional overrides from the locals map
  versioning = each.value.versioning

  # ----- TAGS -----
  tags = {
    Purpose   = "Log Storage"
    ManagedBy = "Terraform"
  }
}
```

Behind the scenes, the private wrapper (`modules/s3-bucket/main.tf`) handles the complexity of calling the public module:

```hcl
# modules/s3-bucket/main.tf

# This is our private wrapper module that sets our standards
module "s3_bucket_public" {
  # Call the vetted public module
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1" # Pin the version for stability

  # ----- Pass-through variables -----
  bucket = var.bucket_name
  tags   = var.tags

  # ----- Enforced Organizational Standards -----
  # These are our opinionated defaults. They can't be overridden easily.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Allow versioning to be controlled, but default to true
  versioning = {
    enabled = var.versioning
  }
}
```

### Step 4: Plan and Apply the Changes

Once the configuration is updated in `locals.tf`, run the standard Terraform workflow.

```bash
# Preview the changes to ensure only your new resource is being created
terraform plan

# If the plan is correct, apply the changes
terraform apply
```

Your new resource will now be created by the public module but will be constrained by the security and compliance guardrails defined in our private wrapper, ensuring it meets our standards without manual effort.