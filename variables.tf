# Provider specific settings

variable "project_name" {
  default     = "devstage"
  description = "The project name aka stage"
}

variable "domain" {
  default     = "bprofitt.koho"
  description = "The project name aka stage"
}

variable "region" {
  default     = "eu-west-1"
  description = "AWS region to speak to"
}

variable "vpc_id" {
  default     = "default"
  description = "VPC to use ('default' for default VPC)"
}

variable "vpc_cidr_block" {
  default     = "10.0.0.0/16"
  description = "The default CIDR range for the subnets in the AZs"
}