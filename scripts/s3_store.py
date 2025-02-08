import boto3
import os
import sys
import botocore
import mimetypes
from dotenv import load_dotenv

# Usecase: Upload files from to_upload directory to S3 bucket
# 1. Get all files from the to_upload directory
# 2. Check if files are already uploaded into the S3 bucket
# 3. Upload files to the S3 bucket
# Add functionality for --dry-run feature: If this flag is set, the script would not move the files to the s3 bucket


# Get all files from the to_upload directory
def get_files():
    current_dir = os.getcwd()
    path = current_dir + "/to_upload"
    files = os.listdir(path)
    return files


# Check if files are already uploaded into the S3 bucket
def check_files(client, bucket, files):
    for file in files:
        try:
            client.head_object(Bucket=bucket, Key=file)
            print(f"File {file} found in the S3 bucket")
        except botocore.exceptions.ClientError as e:
            print(f"File {file} not found in the S3 bucket")


# Upload files to the S3 bucket - given the list of files
def upload_files(client, files, bucket, dry_run):
    if dry_run:
        print("Dry run enabled. Files will not be uploaded to the S3 bucket")
        print("Files would have been uploaded: ", files)
        return

    for file in files:

        content_type = mimetypes.guess_type(file)[0]
        path = f"./to_upload/{file}"

        # Initialize upload_success before uploading the file
        upload_success = None
        with open(path, "rb") as file_path:
            upload_success = client.put_object(
                Body=file_path, Bucket=bucket, Key=file, ContentType=content_type
            )
        if upload_success:
            print(f"Uploaded file {file} to bucket: {bucket}")
        else:
            continue
        # We want to tag the object as uploaded through Python
        tag_success = client.put_object_tagging(
            Bucket=bucket,
            Key=file,
            Tagging={"TagSet": [{"Key": "Orchestration", "Value": "Python"}]},
        )
        if tag_success:
            print(f"Tagged file {file} in bucket: {bucket}")

    return


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
    files = get_files()
    check_files(client, s3_bucket, files)
    upload_files(client, files, s3_bucket, dry_run_flag)


if __name__ == "__main__":
    main(sys.argv[1:])
