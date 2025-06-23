# main.tf

# Automatically merge standard tags with user-provided tags
locals {
  # This ensures your consultancy's tag is always present for tracking.
  standard_tags = {
    ManagedBy = "MyCloudConsultancy" 
  }
  final_tags = merge(local.standard_tags, var.tags)
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = local.final_tags
}

# Block all public access. This is hardcoded and not a variable.
# This is a core security guarantee of this module.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Ownership controls to disable legacy ACLs. This is the modern best practice.
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

# The aws_s3_bucket_acl resource has been REMOVED.
# By setting object_ownership to "BucketOwnerEnforced", ACLs are disabled.
# This simplifies the security model significantly.

# Server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_master_key_id
      sse_algorithm     = var.sse_algorithm
    }
    # S3 Bucket Keys reduce KMS costs. Enable by default when using KMS.
    bucket_key_enabled = var.sse_algorithm == "aws:kms" ? true : null
  }
}

# Versioning configuration
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_status
  }
}

# Simplified Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  // Only create lifecycle rules if at least one of the simple vars is set.
  count = var.expire_objects_after_days > 0 || var.transition_to_ia_after_days > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    id     = "standard-lifecycle-policy"
    status = "Enabled"

    filter {} // Apply to all objects in the bucket

    dynamic "transition" {
      // Only add this block if the variable is set
      for_each = var.transition_to_ia_after_days > 0 ? [var.transition_to_ia_after_days] : []
      content {
        days          = transition.value
        storage_class = "STANDARD_IA"
      }
    }

    dynamic "expiration" {
      // Only add this block if the variable is set
      for_each = var.expire_objects_after_days > 0 ? [var.expire_objects_after_days] : []
      content {
        days = expiration.value
      }
    }

    // Always a good idea to clean up failed multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Access logging (optional) - This was well-designed, no changes needed.
resource "aws_s3_bucket_logging" "this" {
  count = var.logging_target_bucket != null ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix
  
  // Ensure logging is applied after ownership controls are set
  depends_on = [aws_s3_bucket_ownership_controls.this]
}