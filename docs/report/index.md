# S3 Secure Static Website

### Created and Written By - Justin Ng
### Started: January 19, 2025

# Process Documentation

## Terraform Work
Once the architecture was documented and written up, it was time to start working on building the infrastructure out.  I first started by creating the necessary Terraform files that would be needed.  In my approach, I've decided to separate the Terraform resources via service.  For example, the S3 resources would be stored in `s3.tf` while IAM related resources would be managed in `iam.tf`.



### S3
The first thing that I began to work on was the S3 bucket.  Following [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket), I was able to create the bucket.  NOTE: When configuring the bucket, I enabled the `force_destroy` argument as when completing the project I would like to be able to destroy the bucket without removing all the resources inside.  
After the bucket was created, I then created the S3 website configuration and bucket policy associated.  Inside the [s3_bucket_website_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration#with-routing_rules-configured), I wanted to keep the configuration simple by stating only the index and error pages.  Redirect rules are currently out of scope of the project.  Once this was configured, I went into the console to test out the index.html route (see screenshot below).  Once I saw the success, it was time to move onto access and permissions with IAM.

*Screenshots*

*Showcase of bucket being sucessfully created*<br>
<img src="./img/bucket-created.png" alt="bucket-created"/>

*Verifying Static Website Enabled*<br>
<img src="./img/static-website-hosting.png" alt="static-website-hosting"/>

*Testing index.html route*<br>
<img src="./img/hello-world.png" alt="hello-world"/>


### IAM

After the S3 bucket was created, IAM permissions needed to be configured for the bucket.  Following the architecture diagram that was laid out [here](../architecture/index.md), I configured the bucket to public-read through the s3 bucket acl.  Once this was done, I created the bucket policy to be attached.  Before the policy could be created, a role was created to access the S3 bucket through the boto3 API.  The policy would only allow the assume role to have additional action permissions within the bucket including PutObject, DeleteObject, and GetObject.  It is important that the permissions are limited, as we would like to continue to follow the principle of least privilege throughout the project. <br>
The next step in the process was configuring the role itself.  The role needs a policy that can allow access to the S3 bucket.  Similar to the bucket policy, this IAM policy should only allow for the required actions that the script needs.  Once this was done, the IAM user can assume this role in code.  Before proceeding to the next phase of the project, I wanted to confirm my changes were as intended.  This can be shown in the screenshots below.

*Screenshots*

*Showcase of assume role policy added to justin user*<br>
<img src="./img/role-assume-policy.png" alt="assume-policy"/>
(Please note that Administrator privileges were added to run the terraform plans/applies)

*Showcase of bucket policy attachment within s3 bucket*<br>
<img src="./img/bucket-policy.png" alt="bucket-policy"/>

*Challenges*<br>
When working with S3 and IAM, the most challenging part of this portion had to be the interconnected components required to build up infrastructure.  When working with policies, it is important to follow the *principle of least privilege*, allowing only specific resources to have access.  For example, we want only the *role* to be able to create objects in S3.  Others would only be able to view the website and its contents.

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
Error: creating IAM Role (website_access_role): MalformedPolicyDocument: The following Statement Ids are invalid: Assume Role to Access S3 Bucket
```
This error indicated that I was using the SID wrong.  While I was using it as a statement identifier, the way I used it having "Assume Role to Access S3 Bucket" was closer to a description.  As a result, I changed it to `AssumeRolePolicy` and that fixed the problem.

## Detour - Python Coding
Once this was done, I began working on the Python script before moving onto the other architectures.  The reason for this was to confirm that the IAM permissions were sufficient enough to complete the task.  The first thing I did to start this process was look at the available functions for the S3 client.  This was done by reading the [AWS documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html).  After gathering this information, I wanted to create a script that did the following:

```
- Reads from a list of files in a subdirectory called "to-upload"
- Verify these files are supported file types (.html, .css, .jpg, .png, etc.)
- Check if any of these files are inside the bucket already
- If the files are not, upload to the bucket
- If the files are inside the bucket, ask for confirmation before overriding the current version
- List out the files that are successfully uploaded to the bucket
```

As I was working on the script, I began to notice something with how I was configuring my S3 bucket.  In the boto3 documents for [get_object](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3/client/get_object.html), I read about how the objects were encrypted.  By default, the bucket configuration was set to *Server-side encryption with Amazon S3 managed keys (SSE-S3)*.  Essentially, this means that objects are encrypted and decrypted at rest using AES-256 (Advanced Encryption Standard).  Encryption is what keeps our object data in an unreadable format to others.  Without a proper key, users would not be able to properly view these files.  One suggestion that could be made would be creating my own KMS key that I would manage.  This provides more control over security and can further isolate the S3 bucket.  While this may be the case, I chose not to proceed with making an additional KMS key as this was not the original scope of the architecture.

As listed in the challenges, I learned about the importance of `ContentType`.  Using the mimetypes library, I was able to automatically populate this field.  Once this was done, I saw the following result in testing:

```
File styles.css found in the S3 bucket
File index.html found in the S3 bucket
Uploaded file styles.css to bucket: s3-static-website-bucket-7950
Tagged file styles.css in bucket: s3-static-website-bucket-7950
Uploaded file index.html to bucket: s3-static-website-bucket-7950
Tagged file index.html in bucket: s3-static-website-bucket-7950
```

The screenshot of index.html can be found below.  Observe that the index.html file uses the css properties stored from styles.css!

To authenticate the security of our work, I have ran the script without permissions and received the following:

```
botocore.exceptions.ClientError: An error occurred (AccessDenied) when calling the PutObject operation: User: arn:aws:iam::xxxxxxxxxx:user/justin is not authorized to perform: s3:PutObject on resource: "arn:aws:s3:::s3-static-website-bucket-7950/styles.css" because no identity-based policy allows the s3:PutObject action
```

From an outsider's perspective, this is essentially saying that a user cannot put their object into the s3 bucket.  In our case, we want to be able to assume the role to be able to do this in our python code.  Working on the implementations for assuming the role, I utilized [sessions](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/core/session.html) to manage the assumed role.  The assumed role contained the policy that we created in the previous part.  It took some more debugging to update the policy, as I ran into the following error:

```
botocore.exceptions.ClientError: An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:iam::xxxxxxxxxxxx:user/justin is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::xxxxxxxxxxxx:role/s3_website_access_role
```

Once the policy was updated, I realized that we then have to create a new session from the original created (hence `new_session`) that uses the response parameters from the sts.assume_role() function call.  In doing so, after removing the Admin Credentials that were used to create the terraform resources, the script was still able to successfully populate the bucket with files:

```
File styles.css found in the S3 bucket
File index.html found in the S3 bucket
Uploaded file styles.css to bucket: s3-static-website-bucket-7950
Tagged file styles.css in bucket: s3-static-website-bucket-7950
Uploaded file index.html to bucket: s3-static-website-bucket-7950
Tagged file index.html in bucket: s3-static-website-bucket-7950
```

At this stage of the project, I gained a clear understanding of how the policies and principles interacted with the proposed architecture. The bucket policy is the primary policy governing access to the S3 bucket itself. Initially, this policy was correctly configured, with only the S3 Role as the principal for restricted actions.

Three additional policies needed to be created. The first policy was for the S3 role upon creation. This specific policy, `s3_website_access_role`, was intended to grant access to assume the role. Initially, it was configured with `s3.amazonaws.com` as the principal. However, this was incorrect because the *Principal* refers to the entity that is allowed to assume the role. In this case, the user who will be assuming the role needs permission, not the service itself. The second policy, `s3_website_access_policy`, granted the assumed user permissions by attaching it to the IAM role. This policy allowed access to the restricted actions, which would only be granted after the role was assumed. The final policy was for the user `justin`. Without this policy, the user wouldn't have been able to perform the AssumeRole action, even if the role permitted it. To adhere to the principle of least privilege, the policy restricts the Resource to the role ARN.

One key lesson I learned when creating these policies was the distinction between Principal and Resource. The **Principal** defines who the policy applies to, whereas the **Resource** specifies the item or set of resources that can be *affected* by the policy’s actions.

*Additional Challenges*<br>
When working on the Python script, I had a few errors with the boto3 API.  When using the put_object method, I was unable to properly upload files to the bucket.  In my previous implementation, I had:
```
path = f"./to_upload/{file}"
with open(path, "r") as file_path:
    upload_success = s3.put_object(Body=file_path,
                                   Bucket=bucket,
                                   Key=file)
```
The first issue that I noticed was after seeing this error:

```
botocore.exceptions.HTTPClientError: An HTTP Client raised an unhandled exception: a bytes-like object is required, not 'str'
```

This indicated that I was misusing the file itself, as I should be treating the information as bytes rather than strings.  To fix this, I updated the open method to use the following:
```
open(path, "rb")
```

 After seeing that the files were uploaded, I could no longer view them as HTML documents visiting the bucket.  Instead, each time I would visit the S3 website I would be forced to download the file.  After looking through a few fourms, I found that this is because the `ContentType` field in my [put_object](https://stackoverflow.com/questions/18296875/amazon-s3-downloads-index-html-instead-of-serving) method.  Lastly, these changes did not propagate onto the website instantly.  These changes only showed when viewing through an incognito browser.  I believe that this could be due to browser caching and cookies.  Once I cleared my cache, this issue was resolved.


*Screenshots*

*Showcase of S3 Object Encryption Configuration*<br>
<img src="./img/s3-encryption.png" alt="s3-encryption"/>

*Showcase of S3 Object Upload*<br>
<img src="./img/s3-upload.png" alt="s3-upload"/>

## Terraform - GuardDuty

Getting back into the swing of things with Terraform, it was time to start the next part of the project - GuardDuty!  The goal of this part was to assist in scanning the S3 bucket for malicious uploaded files as well as any incoming security events within the specific bucket.  After many challenges (see below), I was able to finally configure the bucket to use GuardDuty.  

Looking at the [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_malware_protection_plan), to get Malware Protection Scanning, an additional resource was created.  To maintain security, a new IAM role was created with an additional policy was created to be referenced in that resource.  A few tests were done once GuardDuty was configured.

Viewing the initial findings (see first screenshot), it stated that the CreateMalwareProtectionPlan was invoked using root credentials.  When creating terraform resources I've used the root credentials.  This is a good lesson to utilize the user `justin` instead.  The second finding warned about allowing Anonymous Access to the S3 bucket.  Since the bucket was configured to be a publicly accessible S3 website, this behavior is intended.  When testing the upload image features, I attempted to upload a dangerous HTML file (malicious.html).  This HTML file was intended to contain a malicious URL that users may click on.  When testing the upload, GuardDuty has tagged the object as "NO_THREATS_FOUND".  Looking into the reason why, GuardDuty does not scan HTML files for vulnerabilities.  Instead, it would be able to detect Malware such as executable files and suspicious traffic to servers.  At this point in the experiment, I did not have a malicious executible and proceeded with the next set of resources to create.

*Challenges*<br>
The error that took the longest was when I had to create the Malware Protection Plan.  

```
│ Error: creating AWS GuardDuty Malware Protection Plan (malware protection)
│
│   with aws_guardduty_malware_protection_plan.protection_plan,
│   on guardduty.tf line 19, in resource "aws_guardduty_malware_protection_plan" "protection_plan":
│   19: resource "aws_guardduty_malware_protection_plan" "protection_plan" {
│
│ operation error GuardDuty: CreateMalwareProtectionPlan, https response error StatusCode: 400, RequestID: 80796efd-3025-4c24-acef-f787e34d4aa2, BadRequestException: The request was rejected because the provided IAM role does not have
│ the required EventBridge PutRule and PutTargets permissions to create a Managed Rule.
```

Looking at various sources, I had ensured that proper S3 actions were accounted for.  What I failed to consider was access to AWS events.  Reading this [article](https://docs.aws.amazon.com/guardduty/latest/ug/malware-protection-s3-iam-policy-prerequisite.html) on the configuration, I followed similarly when creating the policy.  This fixed the problem and the GuardDuty resource was able to be created.

*Screenshots*
*Showcase of GuardDuty Findings in S3 Bucket*<br>
<img src="./img/guardduty-findings.png" alt="guardduty-findings"/>

*Showcase of GuardDuty Tagging for S3 Object*<br>
<img src="./img/guardduty-scan-tag.png" alt="guardduty-scan-tag"/>

*Showcase of GuardDuty Malicious File Attempt*<br>
<img src="./img/guardduty-scan-tag-2.png" alt="guardduty-scan-tag-2"/>
