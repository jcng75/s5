# S3 Secure Static Website

### Created and Written By - Justin Ng
### Started: January 19, 2025

This project was created in inspriation from Tech With Soleyman!  Within this project, I will be creating a static website that is hosted on S3.  The files within S3 are uploaded via an automated Python script.  Access to use this script is managed assuming IAM roles under the account.  Finally, GuardDuty will be used to manage the files that are being uploaded into the S3 bucket!

The following services will be used:
- S3
- IAM
- EventBridge
- SNS
- GuardDuty 

Additionally, these services will be configured via Terraform.

Architecture designs can be found via `docs/architecture` and the report documenting the project developments can be found in `docs/report`!

**Prerequisites**: <br>
- AWS Account
- Access Credentials
- Terraform

**Installation Guides(s)**: <br>
*Terraform* - https://linuxbeast.com/blog/how-to-configure-terraform-on-windows-10-wsl-ubuntu-for-aws-provisioning/

After cloning the repository, please update the backend configuration to your needs in `versions.tf`:
```
# Account-ID is hidden for project security
backend "s3" {
  bucket         = "${var.account_id}-terraform-state-bucket"
  key            = "terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "${var.account_id}-terraform-state-lock-table"
}
```

Within my AWS account, I have provisioned an S3 bucket managing the tfstate file of my terraform code.  Additionally, a DynamoDB table has already been configured to manage terraform locks.  If you would like to have this done for your account as well, I have created a repository that can help you get this set up [here](https://github.com/jcng75/terraform-aws-configuration).  If you would like to manage the tfstate file within your local machine, please remove the `backend "s3"` block.

Once this is configured, run a `terraform plan` alongside a `terraform apply`.  Please note that for my example, you would have to input the desired email address to create the SNS subscription.  To read more about the process of setting that up, please read the report in `docs/index.md`!