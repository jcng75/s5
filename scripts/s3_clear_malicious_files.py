import boto3
import os
import sys
from dotenv import load_dotenv

# Usecase: Remove malicious files from the S3 bucket
# 1. Check if files are malicious based on GuardDuty tags
# 2. If the object does not have that tag ignore it
# 3. If the object has that tag, add it to a list to be deleted
# 4. Delete the files from the S3 bucket in the list
# Add functionality for --dry-run feature: If this flag is set, the script would not remove the files from the s3 bucket

def check_files(client, bucket):
    pass

def remove_files(client, bucket, flag):
    pass

def main(args):
    # We only accept --dry-run as an argument for now
    suitable_args = ["--dry-run"]
    dry_run_flag = False
    for arg in args:
        if arg not in suitable_args:
            print(
                f"Invalid argument: {arg} - Please use one of the following: {suitable_args}"
            )
        else:
            print("Dry run has been enabled.")
            dry_run_flag = True

    load_dotenv()

    session = boto3.Session()
    sts = session.client("sts")
    response = sts.assume_role(
        RoleArn=os.environ["ROLE_ARN"], RoleSessionName="s3rw-session"
    )

    new_session = boto3.Session(
        aws_access_key_id=response["Credentials"]["AccessKeyId"],
        aws_secret_access_key=response["Credentials"]["SecretAccessKey"],
        aws_session_token=response["Credentials"]["SessionToken"],
    )

    client = new_session.client("s3")

    s3_bucket = "s3-static-website-bucket-7950"
    check_files(client, s3_bucket)
    remove_files(client, s3_bucket, dry_run_flag)


if __name__ == "__main__":
    main(sys.argv[1:])