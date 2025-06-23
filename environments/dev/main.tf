# This is the main configuration for the dev environment.
# It will call the reusable modules.
module "s3_bucket" {
  source = "../..//modules/s3_bucket"

  bucket_name            = "aca-dev-testbucket"
  force_destroy          = false
  tags                   = { Environment = "Production" }
  object_ownership       = "BucketOwnerEnforced"
  kms_master_key_id      = "arn:aws:kms:us-west-2:123456789012:key/abcd1234-5678-90ab-cdef-1234567890ab"
  sse_algorithm          = "aws:kms"
  versioning_status      = "Enabled"
  expire_objects_after_days = 365
  transition_to_ia_after_days = 30
}