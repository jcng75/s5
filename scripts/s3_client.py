import boto3


# Wrapper class to create new instances of the s3 client
class s3_client:
    @staticmethod
    def get_instance():
        client = boto3.client("s3")
        return client
