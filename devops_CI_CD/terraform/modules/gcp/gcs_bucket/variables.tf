variable "bucket_name" {
  type        = string
  description = "Name of the GCS bucket to create"
}

variable "region" {
  type        = string
  description = "Region in which the bucket will be created"
}
