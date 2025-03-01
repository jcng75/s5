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


def get_objects(client, bucket):
    response = client.list_objects(Bucket=bucket)
    return [item["Key"] for item in response["Contents"]]


def has_malicious_tag(client, bucket, key):
    response = client.get_object_tagging(Bucket=bucket, Key=key)
    tags = response["TagSet"]
    keys = [tag["Key"] for tag in tags]
    if "GuardDutyMalwareScanStatus" not in keys:
        print(f"Could not find GuardDutyMalwareScanStatus tag in the object: {key}")
        return False
    for tag in tags:
        if not tag["Key"] == "GuardDutyMalwareScanStatus":
            continue
        if tag["Value"] == "THREATS_FOUND":
            print(f"GuardDuty has identified a malicious object: {key}")
            return True
    return False


def check_objects(client, bucket):
    objects_to_delete = []
    objects = get_objects(client, bucket)
    for obj in objects:
        if has_malicious_tag(client, bucket, obj):
            objects_to_delete.append(obj)
    return objects_to_delete


def remove_objects(client, bucket, to_delete, flag):
    if flag:
        print("No objects were removed as Dry Run has been enabled.")
        return True

    for obj in to_delete:
        try:
            client.delete_object(Bucket=bucket, Key=obj)
            print(f"Deleted object: {obj}")
        except Exception as e:
            print(f"Failed to delete object: {obj}")
            print(f"Error: {e}")
            return False

    return True


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
    to_remove = check_objects(client, s3_bucket)
    if len(to_remove) == 0:
        print("No malicious files found in the bucket.")
        return
    else:
        print(f"Identified {len(to_remove)} malicious files to be removed:")
        for obj in to_remove:
            print(f"- '{obj}'")

    response = remove_objects(client, s3_bucket, to_remove, dry_run_flag)

    if response:
        print("All malicious files have been removed.")
    else:
        print("Failed to remove all malicious files.")


if __name__ == "__main__":
    main(sys.argv[1:])
