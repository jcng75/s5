import boto3
import os
import s3_client

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
def check_files():
    pass


# Upload files to the S3 bucket
def upload_files():
    pass


def main(**kwargs):
    files = get_files()
    print(files)
    pass


if __name__ == "__main__":
    main()
