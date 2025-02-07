import boto3
import os
import sys
import botocore
from collections import defaultdict
from s3_client import s3_client

# Usecase: Upload files from to_upload directory to S3 bucket
# 1. Get all files from the to_upload directory
# 2. Check if files are already uploaded into the S3 bucket
# 3. Upload files to the S3 bucket
# 4. Move the uploaded files to the uploaded directory
# Add functionality for --dry-run feature: If this flag is set, the script would not move the files to the s3 bucket


# Get all files from the to_upload directory
def get_files():
    current_dir = os.getcwd()
    path = current_dir + "/to_upload"
    files = os.listdir(path)
    return files


# Check if files are already uploaded into the S3 bucket
def check_files(bucket, files):
    files_sorted = defaultdict(list)
    s3 = s3_client.get_instance()
    for file in files:
        try:
            s3.head_object(Bucket=bucket, Key=file)
            print(f"File {file} found in the S3 bucket")
            files_sorted["uploaded"].append(file)
        except botocore.exceptions.ClientError as e:
            print(f"File {file} not found in the S3 bucket")
            files_sorted["not_uploaded"].append(file)
    
    return files_sorted


# Upload files to the S3 bucket - given the sorted dictionary
def upload_files(files):
    uploaded, new = files["uploaded"], files["not_uploaded"]
    print(uploaded, new)
    pass


def main(*args):
    s3_bucket = "s3-static-website-bucket-7950"
    # print(args)
    files = get_files()
    sorted_files = check_files(s3_bucket, files)
    upload_files(sorted_files)
    pass


if __name__ == "__main__":
    main(sys.argv[1:])
