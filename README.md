Technical prerequisites:
    Terraform 0.12.24
    Kops 1.18.2
    AWS cli: aws-cli/1.17.17 Python/3.8.6 Linux/5.9.8-100.fc32.x86_64 botocore/1.14.17
    Kubectl client verson 1.18.2
    Jq 1.6

    This project was developed on a Fedora 32 machine running zsh

    
-----------------------------------------------------------------

Prerequisites: I assume these do not have to be described in particular detail, as these requirements are documented well in AWS documentation, I will provide references should this be required.

    AWS user has been setup with sufficient access:
        EC2
        EKS
        S3
        VPC
        Route53
        RDS
        SSM Parameter store
        KMS

    This users access and secret keys have been configured as a profile in the aws cli (https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html)
    A S3 bucket needs to be created to store terraform and kops output - please set it to private, i.e. no public access

-----------------------------------------------------------------

Sine this is a local development setup, there are some initial steps that need to be done - consider moving this to a bash script - compatabilitz for other OS? Also point out improvements 
for future = security concerns for credentials, limiting IAM user using roles and specific access, CI/CD pipeline for reproducibility and control, along with additional secrets management

BASH:
export AWS_PROFILE=bartonpriv
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
BASH:

Now to properly simulate a production like process, lets start by creating a terraform workspace to seperate the stages and keep things clean:

BASH:
terraform init

terraform workspace new devstage

terraform apply -auto-approve

aws eks --region $(terraform output region) update-kubeconfig --name $(terraform output cluster_name)

kubectl apply -f qledgerv2.yaml



BASH:
