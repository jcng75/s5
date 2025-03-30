# S5 - Secure Static Simple Storage Service

### Created and Written By - Justin Ng
### Started: January 19, 2025
### Completed: March 2, 2025

# Process Documentation

## Terraform Work
After documenting the architecture, I moved on to building the infrastructure. I began by creating the necessary Terraform files, organizing resources by service. For instance, S3 resources were placed in `s3.tf`, while IAM-related resources were managed in `iam.tf`.


### S3
The first thing that I began to work on was the S3 bucket.  Following [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket), I was able to create the bucket.  **NOTE**: When configuring the bucket, I enabled the `force_destroy` argument as when completing the project I would like to be able to destroy the bucket without removing all the resources inside.  

After the bucket was created, I then created the S3 website configuration and bucket policy associated.  In the [s3_bucket_website_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration#with-routing_rules-configured), I kept the setup simple by only defining the index and error pages, as redirect rules are currently out of scope of the project.  Once this was configured, I went into the console to test out the index.html route (see screenshot below).  Once confirmed successful, it was time to move onto working with IAM.

*Screenshots*

*Showcase of bucket being sucessfully created*<br>
<img src="./img/bucket-created.png" alt="bucket-created"/>

*Verifying Static Website Enabled*<br>
<img src="./img/static-website-hosting.png" alt="static-website-hosting"/>

*Testing index.html route*<br>
<img src="./img/hello-world.png" alt="hello-world"/>


### IAM

After setting up the S3 bucket, the next step was configuring the IAM permissions.  Referring to the [architecture diagram](../architecture/index.md), I configured the bucket to `public-read` through the S3 bucket ACL.  Once this was done, I created the bucket policy to be attached.  Before the policy could be created and attached, a role was created to access the S3 bucket via the `boto3` API.  The policy assigned to this role granted only the necessary permissions—`PutObject`, `DeleteObject`, and `GetObject`—ensuring adherence to the principle of least privilege. Keeping permissions minimal helps maintain security and control within the project.

The next step was configuring the IAM role itself. This role required a policy granting access to the S3 bucket while adhering to the principle of least privilege. Similar to the bucket policy, the IAM policy was designed to allow only the necessary actions required by the script.

Once the policy was applied, the IAM user could assume the role in code. Before moving on to the next phase of the project, I verified that the configurations worked as intended, as shown in the screenshots below.

*Screenshots*

*Showcase of assume role policy added to justin user*
<img src="./img/role-assume-policy.png" alt="assume-policy"/>
(Please note that Administrator privileges were added to run the terraform plans/applies)

*Showcase of bucket policy attachment within s3 bucket*
<img src="./img/bucket-policy.png" alt="bucket-policy"/>

*Challenges*

When working with S3 and IAM, the most challenging aspect of this phase was managing the interconnected components required to build the infrastructure. Configuring policies correctly was crucial, as adhering to the principle of least privilege ensures that only necessary resources have access.

For instance, the IAM role was explicitly granted permission to create objects in S3, while other users were restricted to viewing the website and its contents. This approach minimizes potential security risks while maintaining proper functionality.

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
After configuring IAM for S3, I shifted my focus to developing the Python script before proceeding with other infrastructure components. The primary goal was to validate that the IAM permissions were correctly configured and sufficient for the required tasks.   To start, I first went to review the [AWS documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html) and the available functions for the S3 client.    Based on this research, I wanted to create a script that did the following:

```
- Reads from a list of files in a subdirectory called "to-upload"
- Verify these files are supported file types (.html, .css, .jpg, .png, etc.)
- Check if any of these files are inside the bucket already
- If the files are not, upload to the bucket
- If the files are inside the bucket, ask for confirmation before overriding the current version
- List out the files that are successfully uploaded to the bucket
```

While working on the script, I noticed something important about my S3 bucket configuration.  According to boto3 documentation for [get_object](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3/client/get_object.html), objects stored in S3 are encrypted by default using *Server-side encryption with Amazon S3 managed keys (SSE-S3)*.  This means that objects are automatically encrypted and decrypted at rest using AES-256 (Advanced Encryption Standard).  Encryption is what keeps our object data in an unreadable format to others.  Without a proper key, users would not be able to properly view these files.  

One possible enhancement that could be made in the future would be to create and manage my *own* AWS Key Management Service (KMS) key.  This approach offers more control over security and allows for additional isolate the S3 bucket from other resources.  At the moment, I chose not to proceed with making an additional KMS key as this was beyond original scope of the proposed architecture.

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

To authenticate the IAM permissions have been configured correctly, I ran the script without the `AdministratorAccess` policy and received the following:

```
botocore.exceptions.ClientError: An error occurred (AccessDenied) when calling the PutObject operation: User: arn:aws:iam::xxxxxxxxxx:user/justin is not authorized to perform: s3:PutObject on resource: "arn:aws:s3:::s3-static-website-bucket-7950/styles.css" because no identity-based policy allows the s3:PutObject action
```

This error is saying that a user cannot put their object into the S3 bucket.  In our case, we want to be able to assume the role to be able to do this in our python code.  Working on the implementations for assuming the role, I utilized [sessions](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/core/session.html) to manage the assumed role.  The assumed role contained the policy that we created in the previous part.  It took some more debugging to update the policy, as I ran into the following error:

```
botocore.exceptions.ClientError: An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:iam::xxxxxxxxxxxx:user/justin is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::xxxxxxxxxxxx:role/s3_website_access_role
```

Once the policy was updated, I realized that we then have to create a new session from the original created (hence `new_session`) that uses the response parameters from the sts.assume_role() function call.  In doing so, after removing the Admin permissions that were used to create the Terraform resources, the script was still able to successfully populate the bucket with files:

```
File styles.css found in the S3 bucket
File index.html found in the S3 bucket
Uploaded file styles.css to bucket: s3-static-website-bucket-7950
Tagged file styles.css in bucket: s3-static-website-bucket-7950
Uploaded file index.html to bucket: s3-static-website-bucket-7950
Tagged file index.html in bucket: s3-static-website-bucket-7950
```

At this stage of the project, I had developed a clear understanding of how the policies and access control principles interacted with the proposed architecture. The bucket policy is the primary mechanism governing access to the S3 bucket itself. Initially, this policy was correctly configured, with only the S3 Role as the principal for restricted actions.

Beyond the bucket policy, three additional policies needed to be created.
1. **S3 Role Policy** (`s3_website_access_role`) - Created during the IAM role setup to allow assumption of the role. Initially, it was configured with `s3.amazonaws.com` as the principal. However, this was incorrect because the *Principal* refers to the entity that is allowed to assume the role. In this case, the user who will be assuming the role needs permission, not the service itself.
2. **S3 Role Permissions Policy** (`s3_website_access_policy`) - Attached to the IAM role, this policy allowed access to the restricted actions, which would only be granted after the role was assumed.
3. **IAM User Policy** - This final policy was essential for allowing the user `justin` to perform the `AssumeRole` action. Without it, the role itself would have been properly configured, but the user wouldn’t have had permission to assume it. To maintain the principle of least privilege, this policy restricted access specifically to the role’s ARN.

One key takeaway from this process was understanding the distinction between Principal and Resource. The **Principal** defines who the policy applies to, whereas the **Resource** specifies the item or set of resources that can be *affected* by the policy’s actions.

*Additional Challenges*

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

*Showcase of S3 Object Encryption Configuration* <br/>
<img src="./img/s3-encryption.png" alt="s3-encryption"/>

*Showcase of S3 Object Upload* <br/>
<img src="./img/s3-upload.png" alt="s3-upload"/>

## Terraform - GuardDuty

Getting back into the swing of things with Terraform, it was time to start the next part of the project - GuardDuty!  The goal of this part was to assist in scanning the S3 bucket for malicious uploaded files as well as any incoming security events within the specific bucket.  After many challenges (see below), I was able to finally configure the bucket to use GuardDuty.  

Looking at the [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_malware_protection_plan), to get Malware Protection Scanning, an additional resource was created.  To maintain security, a new IAM role was created with an additional policy was created to be referenced in that resource.  A few tests were done once GuardDuty was configured.

Viewing the initial findings (see first screenshot), it stated that the CreateMalwareProtectionPlan was invoked using root credentials.  When creating terraform resources I've used the root credentials.  This is a good lesson to utilize the user `justin` instead.  The second finding warned about allowing Anonymous Access to the S3 bucket.  Since the bucket was configured to be a publicly accessible S3 website, this behavior is intended.  

While testing the image upload feature, I attempted to upload a potentially dangerous HTML file (malicious.html). This file was designed to contain a malicious URL that users might click on. However, when I checked the scan results, GuardDuty flagged the object as "**NO_THREATS_FOUND**".

Upon further investigation, I discovered that GuardDuty does not scan HTML files for vulnerabilities. Instead, it primarily detects threats such as malware in executable files and suspicious network traffic. Since I did not have a malicious executable file at this stage of testing, I proceeded with creating the next set of resources.

*Challenges*

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

*Showcase of GuardDuty Findings in S3 Bucket* <br/>
<img src="./img/guardduty-findings.png" alt="guardduty-findings"/>

*Showcase of GuardDuty Tagging for S3 Object* <br/>
<img src="./img/guardduty-scan-tag.png" alt="guardduty-scan-tag"/>

*Showcase of GuardDuty Malicious File Attempt* <br/>
<img src="./img/guardduty-scan-tag-2.png" alt="guardduty-scan-tag-2"/>

## SNS

Initially, the next service that I was going to build out was EventBridge.  After reading the terraform [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule), I decided to create the SNS resources first.  According to the documentation, GuardDuty will be configured as the target while EventBridge needs to be able to publish to SNS.  Because of this, SNS needs to be created first.

Creating the SNS components was relatively straightforward.  To understand how SNS works, it's important to define its key components:  
- The **SNS topic** is a communication channel that can be used to send notifications to.  
- The **SNS subscription** is attached to the SNS topic to receive messages.  In our case, the SNS subscription would be configured for emails.

Additionally, an SNS topic policy was created for EventBridge access.  Since EventBridge was not created yet, the Resource was set to **"\*"** for now and will be updated later on.

Once the Terraform code was written and applied, it showed that all 3 resources were created successfully.  In order to get the SNS subscription verified, a confirmation email was sent to the specified email address (see first screenshot).  After clicking the verify link, the SNS infrastructure was complete.  To test that SNS was working, I used the AWS console to publish a **Test Message** to the given email.  After publishing the message, I was able to verify the sent message at my email address (see screenshots)!


*Screenshots*
*AWS Email Confirmation* <br/>
<img src="./img/sns-confirmation.png" alt="sns-confirmation"/>

*Showcase of SNS Topic and Subscription* <br/>
<img src="./img/sns-topic-subscription.png" alt="sns-topic-subscription"/>

*SNS Console Test* <br/>
<img src="./img/sns-test-message.png" alt="sns-test-message"/>

*SNS Test Result* <br/>
<img src="./img/sns-test-result.png" alt="sns-test-result"/>

## EventBridge

EventBridge was the last component that needed to be created in this project.  With that being said, I spent the *most* time working on creating this service, as debugging the various problem was challenging.  EventBridge has 3 main components that needed to be created in Terraform:
- The EventBridge **Bus** is the channel that acts as a bridge between events and other AWS services.  
- In the Event Bus, there are Event **Rules**.  Each rule contains a "Match Pattern" that is used to detect a certain event pattern.  In this case, the event pattern would be looking for GuardDuty and each findings' severity level.  
- The Event **Target** is what we would like to send the event information to.  The target for our case would be the SNS Topic that was created in the previous section.

When working on this component, a decision was made to use the `default` Event Bus.  The reasoning will be explained in the **Challenges** section.  After all the issues were resolved, I made one final test by uploading a malicious executable from a [Kali Linux Virtual Machine](https://www.kali.org/get-kali/#kali-virtual-machines) into the S3 bucket.  The executable was downloaded from *Malware Bazar*.  A GuardDuty Finding was generated and the SNS topic published to my email (see last screenshot)!

*Screenshots*

*Showcase EventBridge Rule not Triggering* <br/>
<img src="./img/eventbridge-severity-rule-graphs.png" alt="eventbridge-severity-rule-graphs"/>

*Retrieve Object Upload JSON Findings* <br/>
<img src="./img/guardduty-findings-export.png" alt="guardduty-findings-export"/>

*Inspect GuardDuty Findings* <br/>
<img src="./img/guardduty-json-results.png" alt="guardduty-json-results"/>

*Test Rule Created* <br/>
<img src="./img/eventbridge-test-rule.png" alt="eventbridge-test-rule"/>

*EventBridge Test Pattern* <br/>
<img src="./img/eventbridge-event-pattern.png" alt="eventbridge-event-pattern"/>

*Test Rule Triggered* <br/>
<img src="./img/eventbridge-test-rule.png" alt="eventbridge-test-rule"/>

*EventBridge GuardDuty Triggered Result* <br/>
<img src="./img/eventbridge-guardduty-connect.png" alt="eventbridge-guardduty-connect"/>

*Challenges*

The first challenge that I ran into was configuring the resources:
```
│ Error: "rule" cannot be longer than 64 characters: "arn:aws:events:us-east-1:xxxxxxxxxxxx:rule/guardduty_event_bus/guardduty_severity_rule"
│
│   with aws_cloudwatch_event_target.sns,
│   on eventbridge.tf line 16, in resource "aws_cloudwatch_event_target" "sns":
│   16:   rule      = aws_cloudwatch_event_rule.guardduty_event_rule.arn
│
╵
╷
│ Error: "rule" doesn't comply with restrictions ("^[0-9A-Za-z_.-]+$"): "arn:aws:events:us-east-1:xxxxxxxxxxxx:rule/guardduty_event_bus/guardduty_severity_rule"
│
│   with aws_cloudwatch_event_target.sns,
│   on eventbridge.tf line 16, in resource "aws_cloudwatch_event_target" "sns":
│   16:   rule      = aws_cloudwatch_event_rule.guardduty_event_rule.arn
│
```

To fix this error, rule had to be configured to use name instead of arn.

```
│ Error: creating EventBridge Target (guardduty_severity_rule-SendToSNS): operation error EventBridge: PutTargets, https response error StatusCode: 400, RequestID: e3b68bec-b11e-4325-8bb2-8ba522478cd7, ResourceNotFoundException: Rule guardduty_severity_rule does not exist on EventBus default.
│
│   with aws_cloudwatch_event_target.sns,
│   on eventbridge.tf line 15, in resource "aws_cloudwatch_event_target" "sns":
│   15: resource "aws_cloudwatch_event_target" "sns" {
```
To fix this error, the cloudwatch_event_target had to be configured to include the event_bus_name field.

The last issue I encountered was testing the submission of GuardDuty findings to the EventBridge bus. Debugging this issue proved to be quite challenging, as there were several components to address before reaching a conclusion.

From my perspective, GuardDuty was correctly identifying malicious S3 objects, as the findings were displayed within the GuardDuty console. However, the event was not being passed to the custom EventBridge bus (see the first screenshot). This issue appeared to be related to the EventBridge *rule*, but it also impacted the EventBridge bus itself.

Additional changes I made were IAM related. I noticed that the EventBus policy was not configured.  Adding the [aws_cloudwatch_event_bus_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus_policy), this enabled the bus to receive events from GuardDuty.  Additionally, I created the `eventbridge_guardduty_role`, which allowed EventBridge to publish to the SNS topic.

The next thing I tried was testing the event from the console.  In each Event Bus, there is a feature to `Send Events`, which accepts an event source, detail type, and detail content.  To get the detail content, I retrieved the data by exporting the finding JSON from GuardDuty (see screenshots).  My current `event_pattern.json` uses `aws.guardduty` as the source.  One thing that I ran into when testing was that I was not "authorized" to use this source.  After looking into [this](https://repost.aws/questions/QU9O1i3AITRTqn32Kf6yTxFA/eventbridge-to-lambda-notauthorizedforsourceexception), I discovered that the event source cannot use "aws".  Instead, I changed the source to use `test.guardduty` in a test rule (see screenshots).  Doing this, I was able to confirm the event pattern and published to the SNS topic.

The final step was addressing the question of how to connect the EventBus to GuardDuty. By default, GuardDuty findings are sent to the **default** EventBridge bus. To have the findings sent to a custom bus, the events would need to be propagated from the default bus.

To keep things simple, I decided to move my findings and resources to the default bus. Once I did this, I was able to successfully generate a GuardDuty finding, and I saw a successful SNS notification being sent! This confirmed that the integration between GuardDuty, EventBridge, and SNS was working as intended.

Looking back on the challenge, I realized that creating a CloudWatch Log Group would have been helpful in tracking errors related to the issues I encountered. Moving forward, I plan to implement this practice in future AWS developments to better monitor and troubleshoot problems more efficiently.

## Python Scripting - Clearing S3 Malicious Files

As I was working on configuring GuardDuty with EventBridge, another idea that came to mind was to automate the removal of any malicious files identiified within the S3 bucket.  The identification process would be similar to the `s3_store.py` script, but this time it removes any GuardDuty-scanned objects that were tagged as a threat (THREATS_FOUND).  

Using `s3_store.py` as a reference, I ran into minimal issues when creating the new script `s3_clear_malicious_files.py`.  When testing the script on my local machine, I encountered the following results:

`Using --dry-run argument:`
```
python3 s3_clear_malicious_files.py --dry-run
Dry run has been enabled.
Could not find GuardDutyMalwareScanStatus tag in the object: error.html
Could not find GuardDutyMalwareScanStatus tag in the object: malware-protection-resource-validation-object
GuardDuty has identified a malicious object: out.bin
Identified 1 malicious files to be removed:
- 'out.bin'
No objects were removed as Dry Run has been enabled.
```

`Without --dry-run argument`
```
python3 s3_clear_malicious_files.py
Could not find GuardDutyMalwareScanStatus tag in the object: error.html
Could not find GuardDutyMalwareScanStatus tag in the object: malware-protection-resource-validation-object
GuardDuty has identified a malicious object: out.bin
Identified 1 malicious files to be removed:
- 'out.bin'
Deleted object: out.bin
All malicious files have been removed.
```

After running the script, I checked the S3 bucket and confirmed that the `out.bin` object, which was flagged as a threat, was successfully removed from the bucket! However, I noticed that error.html was not properly tagged by GuardDuty.

Upon further investigation, I realized that this happened because the error.html object was uploaded *before* GuardDuty was correctly configured for the S3 bucket. As a result, GuardDuty did not have the necessary configuration to scan and tag it as a threat at the time it was uploaded.

## Cost Analysis

When going into the Root User to view the current costs within the account, the total was still $0.00 (see screenshot)!  This is due to the account being under the `Free Tier`.  AWS offers free monthly limits that give users an opportunity to build out infrafrastructure patterns.  For example, Free Tier offers 5 GB of storage free of charge every month.  In our case, S3, EventBridge, SNS, and GuardDuty were covered so charges were incurred during this project.

To read more about Free Tier account resource limits, you can do so [here](https://aws.amazon.com/free/).

*AWS Cost Results* <br/>
<img src="./img/aws-cost-result.png" alt="aws-cost-results"/>

## Dismantling Project Resources

Once the project was complete, it was important to destroy the resources created in my account to prevent any additional costs. While there are no charges at the moment due to the Free Tier account, costs may be incurred once the Free Tier trial ends.  Since the project was written using Terraform, I could simply run the `terraform destroy` command that would cause all the resources to be removed.

One minor issue that I encountered was trying to remove the AWS GuardDuty Malware Protection Plan.  The issue I was having was this error:

```
aws_guardduty_malware_protection_plan.protection_plan: Destroying... [id=acca817ce14c516012c2]
╷
│ Error: deleting AWS GuardDuty Malware Protection Plan ("acca817ce14c516012c2")
│
│ operation error GuardDuty: DeleteMalwareProtectionPlan, https response error StatusCode: 400, RequestID: 9fd82134-d740-4930-9026-ef7a808e90a0, BadRequestException: The request was rejected because the provided
│ IAM role cannot be assumed by the service.
╵
```

When checking the console, I discovered that the IAM Role created for the project had been deleted before the protection plan could be disabled. To resolve this, I reassigned a temporary role through the console, which I then terminated after rerunning the `terraform destroy` command.

To prevent this issue in the future, I updated the Terraform configuration by adding a `depends_on` clause to the IAM Role and policy. This ensures that GuardDuty's Malware protection for S3 is disabled *before* those resources are destroyed, preventing any premature deletions or issues during the cleanup process.

Once this was done, all of the resources that have been created were removed from terraform state and within the account!

## Reflections

After completing this project, there were many takeways that I had:
- **Designing architecture can be easier than implementing the design** <br>
  Initially, I believed that implementing a well-thought-out architectural diagram would be smooth sailing. I had assumed that with a solid diagram detailing the relationships between components, everything would fall into place. However, this proved to be more complex than anticipated, as each component had its own set of intricacies that needed to be understood and managed.

- **Starting from scratch can be difficult!** <br>
  This is especially true in the context of infrastructure. Many components required additional configuration or settings not explicitly outlined in the architecture diagram. While I intentionally kept the diagram simple to enhance understanding, there were underlying aspects that were not captured. Even though I currently work with Terraform at my company, building a new repository without a reference can be challenging. However, the challenge provided substantial technical learning that will benefit similar future projects.

- **Debugging Infrastructure can be improved** <br>
  As discussed in the EventBridge section, I didn’t fully optimize my debugging approach. In several cases, I could have handled challenges more efficiently. Moving forward, I aim to improve my debugging skills and speed up problem-solving by leveraging AWS's built-in services, such as CloudWatch Log Groups and CloudTrail Trails.

- **Security in the Cloud is important!** <br>
  Although the initial goal was to build a "secure" static website on S3, the project ended up being more about securing the permissions to upload and remove files from the bucket. The website itself was publicly accessible for viewing static content, but security was ensured with IAM roles and policies governing file management and GuardDuty for malware detection. This project reaffirmed the importance of adhering to the principle of least privilege, limiting access to only the required users or resources.

- **Optimizations can always be made!** <br>
  As discussed in previous sections above, there were a few areas where improvements could have been made:
    - Working on S3, locating to the S3 Website was difficult.  To fix this, we could add a Route53 domain that would have a record pointing to the S3 endpoint.
    - As discussed in the EventBridge section, the default bus was used for the Event Rule and Event Target.  Ideally, these resources should be in their own custom Event Bus, as having all rules inside the default bus can get tricky to manage.
    - To provision the resources, I used the user `justin` that was already created before starting the project.  Ideally, this user's permissions should be separate from the role and policies that were associated.  To improve this, a new **separate** user should be created instead.
    - Outside of AWS, the current repo is not using runners for each github PR.  To improve the checks being made on each commit, a CI pipeline can be created to run these pre-commit checks through automation.

- **Proud of the work that was done!** <br>
  This project turned out to be more time-consuming than initially expected. I originally thought it would take only a few days to complete, but it ended up taking almost a month and a half. The main reasons for the time investment were resource creation through IaC and the importance of thorough documentation. This experience reinforced the value of organization and attention to detail for future projects. I look forward to maintaining a high standard of quality in my work as I continue my journey as a Cloud Engineer!

If you've read this far, I would just like to give you a big thank you for your support!  Hope to see you soon in projects to come!

<img src="./img/aws-logo.png" alt="aws-logo"/>
