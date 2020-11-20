
variable "region" {
  default     = "eu-west-1"
  description = "AWS region to speak to"
}

variable "vpc_name" {
  default     = "koho-vpc"
  description = "VPC to use ('default' for default VPC)"
}

variable "vpc_cidr_block" {
  default     = "10.0.0.0/16"
  description = "The default CIDR range for the subnets in the AZs"
}

variable "s3_bucket" {
  default     = "bprofitt"
  description = "The default S3 bucket to store terraform state file"
}