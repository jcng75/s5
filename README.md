# S3 Secure Static Website

### Created and Written By - Justin Ng
### Started: January 19, 2025

This project was created in inspriation from Tech With Soleyman!  Within this project, I will be creating a static website that is hosted on S3.  The files within S3 are uploaded via an automated Python script.  Access to use this script is managed assuming IAM roles under the account.  Finally, GuardDuty will be used to manage the files that are being uploaded into the S3 bucket!

The following services will be used:
- S3
- IAM
- GuardDuty
Additionally, these services will be configured via *Terraform*.

Architecture designs can be found via `docs/architecture` and the report documenting the project developments can be found in `docs/report`!