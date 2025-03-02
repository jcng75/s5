# S5 - Secure Static Simple Storage Service

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

**Prerequisites**:

- AWS Account
- Access Credentials
- Terraform
- WSL2 (Preferred)

**Installation Guides(s)**:

*Terraform* - https://linuxbeast.com/blog/how-to-configure-terraform-on-windows-10-wsl-ubuntu-for-aws-provisioning/

*AWS* - https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

*AWS CLI Configuration* - https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-files.html

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

Once this is configured, run a `terraform plan` alongside a `terraform apply`.  Please note that for my example, you would have to input the desired email address to create the SNS subscription.  The current default email has been set to `justinchunng@gmail.com`.  This would have to be updated in [here](https://github.com/jcng75/s3-secure-static-website/blob/main/terraform/variables.tf) under `email_address`. To read more about the process of setting that up, please read the report in `docs/index.md` within the SNS section!

Additionally, ensure the data source `aws_iam_user` is configured to the IAM user in your account that you would like to provision resources with.  In my example, the user was configured to **justin**.

In order to use the Python Scripts created, an `.env` file needs to be made within the `scripts/` subdirectory.  In each script, a **ROLE_ARN** is needed to be able to have access with using the S3 bucket.  After running the terraform commands, the outputs should generate an ARN under the name `role_s3_role_arn`.  In doing so, please populate the `.env` file with the value.
```
ROLE_ARN="arn:aws:iam::xxxxxxxxxxxx:role/s3_website_access_role"
```
Additionally, ensure that the S3 bucket name matches your Terraform configuration (**default:** `s3-static-website-bucket-7950`).

The Python3 library packages must also be installed.  In the `scripts/` subdirectory, please create a virtual environment using the following set of commands:

```
# If venv is not installed
sudo apt-get upgrade
sudo apt-get install python3-venv
```

```
# Create the virtual environment
python3 -m venv .venv

# Activate the environment
source .venv/bin/activate

# Install the requirements
pip install -r requirements.txt
```

Don't hesitate to share any feedback or concerns about the project using the contact information provided below. Also, if there's anything else you'd like to discuss, feel free to reach out!

[Email](mailto:justinchunng@gmail.com) <br>
[LinkedIn](https://www.linkedin.com/in/justinchunng/) <br>
[GitHub](https://github.com/jcng75)
