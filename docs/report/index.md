# S3 Secure Static Website

### Created and Written By - Justin Ng
### Started: January 19, 2025

# Terraform Work
Once the architecture was documented and written up, it was time to start working on building the infrastructure out.  I first started by creating the necessary Terraform files that would be needed.  In my approach, I've decided to separate the Terraform resources via service.  For example, the S3 resources would be stored in `s3.tf` while IAM related resources would be managed in `iam.tf`.


## Process

### S3
The first thing that I began to work on was the S3 bucket.  Following [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket), I was able to create the bucket.  NOTE: When configuring the bucket, I enabled the `force_destroy` argument as when completing the project I would like to be able to destroy the bucket without removing all the resources inside.  
After the bucket was created, I then created the S3 website configuration and bucket policy associated.  Inside the [s3_bucket_website_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration#with-routing_rules-configured), I wanted to keep the configuration simple by stating only the index and error pages.  Redirect rules are currently out of scope of the project.  

*Screenshots*

### IAM


**Challenges**
When working with Terraform, the most challenging part of this portion had to be the interconnected components required to build up infrastructure.  When working with policies, it is important to follow the *principle of least privilege*, allowing only specific resources to have access.  For example, we want only the *role* to be able to create objects in S3.  Others would only be able to view the website and its contents.

When running the S3 resource applies, I ran into the following error message attempting to create the S3 bucket policy and attaching it to the S3 Bucket:

```
Error: Error putting S3 policy: AccessDenied: User: arn:aws:iam::xxxxxxxxxx:user/justin is not authorized to perform: s3:PutBucketPolicy on resource: "arn:aws:s3:::s3-static-website-bucket-7950" because public policies are blocked by the BlockPublicPolicy block public access setting.
```

After doing [research](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl), I found that I had not configured the S3 Bucket ACL via terraform.  After doing so, I was able to properly view the bucket and its contents.

When configuring the policies, I saw a few errors:
```
Error: Error putting S3 policy: MalformedPolicy: Invalid policy syntax.
```
After looking into it, I learned that this can be caused by the Principal field misrepresented as a string rather than its inteded object.  After making the change, it looked like this:

```
    Principal = {
      AWS = aws_iam_role.website_access_role.arn
      }
```
For the IAM Policy, I had this error:
```
Error: creating IAM Role (s3_website_access_role): MalformedPolicyDocument: The following Statement Ids are invalid: Assume Role to Access S3 Bucket
```
This error indicated that I was using the SID wrong.  While I was using it as a statement identifier, the way I used it having "Assume Role to Access S3 Bucket" was closer to a description.  As a result, I changed it to `AssumeRolePolicy` and that fixed the problem.
