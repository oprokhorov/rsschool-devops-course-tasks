# Task 1: AWS Account Configuration

Follow the instructions in [Task_1](https://github.com/rolling-scopes-school/tasks/blob/master/devops/modules/1_basic-configuration/task_1.md). My notes for specific steps can be found below:

## 1. Install AWS CLI and Terraform

aws cli is simple msi install on windows. For terraform download exe file and add folder path to PATH env variable.

## 2. Create IAM User and Configure MFA
Go to IAM > Users > Create user > **RSSchoolTerraform** > Next > Create user. We will use it for terraform running on our laptop

Click **RSSchoolTerraform** user > Security credentials > Multi-factor authentication (MFA) > Assing MFA devide > specify MFA device name (how it would be called on your authenticator app) > Authenticator app > Show QR code > Scan it with Google > enter two consecutive codes to fields below > click add MFA

Click **RSSchoolTerraform** user > Access keys > create access key

## 3. Configure AWS CLI
Create access key & secret and and configure aws cli to use these credentials on your laptop:
```bash
aws configure
```
During config specify region to us-east-1 as it is the cheapest one

Terraform will automatically pick up these credentials and authenticate with AWS

## 5. Create a bucket for Terraform states
It is generally recommended to create S3 bucket for terraform backend outside of the project which needs to store state, so we will create it manually from aws cli:

Create s3 bucket for terraform state and enable versioning
```bash
aws s3api create-bucket --bucket terraform-state-bucket-87f4 --region us-east-1
aws s3api put-bucket-versioning `
  --bucket terraform-state-bucket-87f4 `
  --versioning-configuration Status=Enabled
```
Encryption at rest is enabled by default.

Navigate to S3 > newbucketname > Permissions > Bucket policy > Edit > paste the policy from the code block below and click save changes. The policy grants our terraform user necessary permissions and enforces HTTPS encryption:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowTerraformAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::824525457054:user/RSSchoolTerraform"
            },
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::terraform-state-bucket-87f4",
                "arn:aws:s3:::terraform-state-bucket-87f4/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "true"
                }
            }
        }
    ]
}
```
## 6. Create an IAM role for Github Actions(Additional task)
at this point we have terraform working locally, so we can create the role with IaC. For this run:
```bash
terraform init
terraform plan
terraform apply
```
Which should create the github role, trust policy for it as well as s3 bucket

## 7. Configure an Identity Provider and Trust policies for Github Actions(Additional task)

Go to IAM > Roles > GithubActionsRole and verify attached permissions and trust policy created from code in previous step.

## 8. Create a Github Actions workflow for deployment via Terraform
This task implements the worflow. 