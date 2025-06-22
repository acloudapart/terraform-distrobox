# variables.tf

variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  type        = bool
  default     = false
}

# --- OPINIONATED DEFAULTS ---

variable "versioning_status" {
  description = "The versioning state of the bucket. Recommended to keep 'Enabled' for data protection."
  type        = string
  default     = "Enabled"
}

variable "object_ownership" {
  description = "Specifies object ownership rules. 'BucketOwnerEnforced' is the modern best practice, disabling ACLs."
  type        = string
  default     = "BucketOwnerEnforced"
}

variable "sse_algorithm" {
  description = "The server-side encryption algorithm to use. Use 'aws:kms' for KMS-managed keys or 'AES256' for S3-managed keys."
  type        = string
  default     = "AES256"
}

variable "kms_master_key_id" {
  description = "The AWS KMS key ID to use for encryption. Only applicable when sse_algorithm is 'aws:kms'."
  type        = string
  default     = null
}

# --- SIMPLIFIED LIFECYCLE ---

variable "expire_objects_after_days" {
  description = "Number of days after which to expire objects. Set to 0 to disable."
  type        = number
  default     = 0
}

variable "transition_to_ia_after_days" {
  description = "Number of days after which to transition objects to Standard-IA storage. Set to 0 to disable."
  type        = number
  default     = 0
}

# --- OPTIONAL LOGGING ---

variable "logging_target_bucket" {
  description = "The name of the bucket to send access logs to. If null, logging is disabled."
  type        = string
  default     = null
}

variable "logging_target_prefix" {
  description = "A prefix for the log object keys."
  type        = string
  default     = null
}