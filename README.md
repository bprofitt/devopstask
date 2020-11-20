# Technical takehome DevOps task

The task requires a few main points to be addressed:
 - You need to provision an app connecting to a sql database.
 - The deployment needs to be highly available (HA), multiple zones or regions
 - Pick an application that depends on a database to deploy, here is a suggestion:
   - [QLedger](https://github.com/RealImage/QLedger)

## Design considerations

Since this is a local task I could not use a full DevOps strategy, the shortcomings I will discuss later in the document.

To address the requirements set out as part of the task, I designed the setup as follows following industry best-practices by splitting the infrastructure and application parts and utilizing IAC tooling by leveraging Terraform and AWS EKS.

### Infrastructure

An AWS VPC compromising of 3 Availability Zones (AZ or az), application and database subnets in each AZ. A multi-az AWS managed RDS (Postgress) is also provisioned as a multi-az service across the 3 AZs for more resilience in case of failure. 

Terraform is used to create and maintain changes made to the state of the infrastructure via a remote state mechanism utilizing S3 - this will allow the solution to be ported to a CI/CD pipeline more easily and also allow multiple colleagues to work on the infrastructure - there is a caveat here as the solution needs to be built out to utilize a DynamoDB table for statelocks - this is already present in the provider.tf file but is commented out for now.

### Application

The task requires an application (QLedger) to connect to a database, so I created Dockerhub image of QLedger in order to customize a few things for ease of deployment as well as security. The application is deployed across the multiple AZs and also sits behind a AWS NLB in order to provide high availability, proper load balancing across the instances as well as future integration into a DNS zone to further abstract the API functionality.

Kubernetes is used to deploy the application as well as the loadbalancer to the AWS EKS cluster. AWS EKS was chosen as this takes away the need to dive under the hood to setup, maintain and update the control plane and is also certified kubernetes certified, allowing all upstream kubernetes applications to run on it.

I also forked QLedger ([forked QLedger](https://github.com/bprofitt/QLedger)) in order to utilize [aws-env](https://github.com/Droplr/aws-env) to securely handle the database credentials created dynamically by terraform, as well as being able to create a DockerHub image that can be versioned controlled and available. I have also created an additional IAM policy via terraform to allow the kubernetes nodes to access AWS SSM and AWS KMS services in order for this credential sharing mechanism to work.


## Technical prerequisites:
- Terraform 0.12.24
- AWS cli: aws-cli/1.17.17 Python/3.8.6 Linux/5.9.8-100.fc32.x86_64 botocore/1.14.17
- Kubectl client version 1.18.2
- Jq 1.6
- Git 2.26.2
- This project was developed on a Fedora 32 machine running zsh


## Prerequisites:

I assume these prerequisites do not have to be described in particularly fine detail, as the steps are well documented in the AWS documentation, I will provide references should this be required.

- AWS user has been setup with sufficient access to:
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


## Deployment

Since this is a local development setup, there are some initial steps that need to be done, such as exporting the neccesary keys and aws profile for terraform to work.

**Note: all text in blocks are commands to be executed in a \*nix shell**


    export AWS_PROFILE=<PLEASE CHANGE TO AWS PROFILE MENTIONED IN PREREQUISITES>

    export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
    
    export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)


First get the code from github and change the S3 bucket used for the terraform statefile:

    git clone https://github.com/bprofitt/devopstask.git

    cd devopstask/

Please edit the *provider.tf* file and replace the value "bprofitt" with the S3 bucket name that was created as part of the prerequisites:

    bucket         = "bprofitt"

We can now download the required terraform modules as well as to properly simulate a production like process, we also create a terraform workspace to seperate the stages and keep things clean.

    terraform init

    terraform workspace new devstage

Instantiating the infrastructure:

    terraform apply -auto-approve

This process will take around 10 minutes to create the infrastructure, most of the time is spent creating the elastic kubernetes service and the multi-az database service.

Once the infrastructure is ready, we can continue to deploy our application:

    aws eks --region $(terraform output region) update-kubeconfig --name $(terraform output cluster_name)

    kubectl apply -f qledgerapp.yaml

    kubectl apply -f qledgerlb.yaml

    kubectl get services

The last command will return the loadbalancer's externally resolvable DNS name that we can use to interact with the application. This takes some time to return a proper value, so please allow a few minutes for DNS propagation and AWS to finish.


*Once done testing and verifying the functionality, please remember to destroy the stack, otherwise costs will be incurred!*

    kubectl delete all --all
    
    terraform destroy -auto-approve

## Testing the solution:

As this is a DevOps task not destined to be immediately production ready, I have created a simple authorization code to use when interacting with the QLedger API.

    1234567890

The following examples can be used to test the functionality of the clustered application - there are multiple tools that can be used to send the requests, for a quick check [REQBIN](https://reqbin.com/req/yjok4snr/post-html-form-example) can easily used to test the functionality shown below:

```
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
```
```
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
```

```
POST /v1/transactions HTTP/1.1
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
```

```
POST /v1/transactions/_search HTTP/1.1
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
```

# Future Improvements:

- Use a dedicated IAM user
- Use assume role functionality and more restrictive IAM policies to limit the blast radius should the dedicated account become compromised
- Port the project to a proper CI/CD pipeline
  - This will allow for repeatability with regards to deployments and separation of environments
  - Minimizing manual error(s)
  - Increased security for credentials
  - Better SDLC process
  - Automated testing
- Create stronger authentication token for the service, stored in SSM parameter store and distributed securely to calling applications
- Change the subnets to be private and introduce a hardened bastion host for access to the infrastructure
- If this is to be a public facing service, add kubernetes certificate manager for HTTPS encrypted traffic 
- Increase monitoring - as this is the only way to have visibility on the health and bottlenecks of a platform 
  - Integrate kubernetes metric and dashboard applications for cluster level monitoring and visibility
  - Integrate prometheus/grafana for application level monitoring and visibility


## Some final thoughts

There are many ways to create a kubernetes cluster and its underlying infrastructure, the tooling used here was a choice out of many, however the advantages are clear from the choices made as well as to the split between infrastructure and the application layers.

Terraform works best as infrastructure-as-code tooling by creating and maintaining the state of the infrastructure, the remote state functionality allows different people/teams to work on and maintain the infrastructure and does not interfere with the application operations part, though there are dependencies.

Kubernetes alls us to also abstract the application layer away from a dependency to the infrastructure, we can scale the infrastructure and the kubernetes control plane will grow and shrink with it as well as maintaining the optimal number of instances of the application running as well as also being to scale the number of instances of the application independently of the underlying infrastructure.
