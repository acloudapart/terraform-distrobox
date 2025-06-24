module "s3_bucket" {
  for_each = local.buckets

  source = "../../../modules/s3_bucket"

  bucket_name            = each.value.bucket_name
  force_destroy          = each.value.force_destroy
  tags                   = each.value.tags
  object_ownership       = each.value.object_ownership
  kms_master_key_id      = each.value.kms_master_key_id
  sse_algorithm          = each.value.sse_algorithm
  versioning_status      = each.value.versioning_status
  expire_objects_after_days = each.value.expire_objects_after_days
  transition_to_ia_after_days = each.value.transition_to_ia_after_days
}
