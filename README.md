# Technical takehome DevOps task

The task requires a few main points to be addressed:
 - You need to provision an app connecting to a sql database.
 - The deployment needs to be highly available (HA), multiple zones or regions
 - Pick an application that depends on a database to deploy, here is a suggestion:
    - https://github.com/RealImage/QLedger

## Design considerations

Since this is a local task I could not use a full DevOps strategy, the shortcomings I will discuss later in the document.
To address the requirements set out as part of the task, I designed the setup as follows following industry best-practices by splitting the infrastructure and application parts and utilizing IAC tooling:

### Infrastructure
A AWS VPC compromising of 3 Availibility Zones (AZ), application and database subnets in each AZ. A multi-az AWS managed RDS (Postgress) is also provisioned across the 3 AZs for more resilience in case of failure.

### Application
The task requires an application (QLedger) to connect to a database, so I created Dockerhub image of QLedger in order to customize a few things for ease of deplyment as well as security. The application is deplozed across the multiple AZs and also ssits behind a AWS NLB in order to provide high availibility, proper load balancing across the instances as well as future integration into a DNS zone to further abstract the API functionality.

## Technical prerequisites:
    Terraform 0.12.24
    AWS cli: aws-cli/1.17.17 Python/3.8.6 Linux/5.9.8-100.fc32.x86_64 botocore/1.14.17
    Kubectl client verson 1.18.2
    Jq 1.6

    This project was developed on a Fedora 32 machine running zsh

    
-----------------------------------------------------------------

## Prerequisites:

I assume these do not have to be described in particular detail, as these requirements are documented well in AWS documentation, I will provide references should this be required.

- AWS user has been setup with sufficient access:
  - EC2
  - EKS
  - S3
  - VPC
  - Route53
  - RDS
  - SSM Parameter store
  - KMS

- This users access and secret keys have been configured as a profile in the aws cli (https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html)
- A S3 bucket needs to be created to store the terraform state - please set it to private, i.e. no public access

-----------------------------------------------------------------

Sine this is a local development setup, there are some initial steps that need to be done:

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

kubectl apply -f qledgerapp.yaml

kubectl apply -f qledgerlb.yaml


BASH:

-----------------------------------------------------------------
Testing the solution:


POST /v1/accounts HTTP/1.1
Authorization: 1234567890
Host: ad424889b6fd14afaa011df83c1bd7ad-ba13ed59f6836365.elb.eu-west-1.amazonaws.com
Accept: application/json
Content-Type: application/json
Content-Length: 80

{
  "id": "bob",
  "data": {
    "product": "qw",
    "date": "2017-01-01"
  }
}


POST /v1/accounts HTTP/1.1
Authorization: 1234567890
Host: ad424889b6fd14afaa011df83c1bd7ad-ba13ed59f6836365.elb.eu-west-1.amazonaws.com
Accept: application/json
Content-Type: application/json
Content-Length: 80

{
  "id": "alice",
  "data": {
    "product": "qw",
    "date": "2017-01-01"
  }
}

working:

POST /v1/accounts HTTP/1.1
Authorization: 1234567890
Host: ad424889b6fd14afaa011df83c1bd7ad-ba13ed59f6836365.elb.eu-west-1.amazonaws.com
Accept: application/json
Content-Type: application/json
Content-Length: 154

{
  "id": "abcd1234",
  "lines": [
    {
      "account": "alice",
      "delta": -100
    },
    {
      "account": "bob",
      "delta": 100
    }
  ]
}




POST //v1/transactions/_search HTTP/1.1
Authorization: 1234567890
Host: ad424889b6fd14afaa011df83c1bd7ad-ba13ed59f6836365.elb.eu-west-1.amazonaws.com
Accept: application/json
Content-Type: application/json
Content-Length: 22

{
  "id": "abcd1234"
}

HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Date: Fri, 20 Nov 2020 09:53:51 GMT
Content-Length: 141

[{"id":"abcd1234","timestamp":"2020-11-20T09:52:58.998Z","data":{},"lines":[{"account":"alice","delta":-100},{"account":"bob","delta":100}]}]

-----------------------------------------------------------------
# Future Improvements:

 - consider moving this to a bash script - compatabilitz for other OS? Also point out improvements 
for future = security concerns for credentials, limiting IAM user using roles and specific access, CI/CD pipeline for reproducibility and control, along with additional secrets management