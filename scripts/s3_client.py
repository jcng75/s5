import boto3

# Singleton class to create a single instance of the s3 client
class s3_client:
    def __init__(self):
        self.instance = None
    
    @staticmethod
    def get_instance():
        if not s3_client.instance:
            s3_client.instance = boto3.client('s3')
        return s3_client.instance