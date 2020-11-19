provider "aws" {
  region  = var.region
}
terraform {
	required_version = ">= 0.12.14"
	backend "s3" {
	  bucket         = "bprofitt"
	  key            = "eksstate/terraformkoho.state"
	  region         = "us-east-1"
	  # Following settings to allow for statelock when multiple people work on the same project / TBD if needed for this task
	  # dynamodb_table = "koho-tflocks"
	  # encrypt        = true
	}
}