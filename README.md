# AWS Lab 01 — Introduction to AWS IAM

This lab uses **AWS Identity and Access Management (IAM)** to give three new employees access that matches their jobs. Each user is added to a group, and the policy attached to that group decides what the user can do.

## What this lab covers

- Looking at IAM users and groups that already exist
- Reading the IAM policies attached to those groups
- Adding users to groups to match a business scenario
- Signing in with the account's IAM sign-in URL
- Checking that each user can do what their policy allows, and nothing more

## Key concepts

| Concept | Meaning |
| --- | --- |
| **User** | One identity (a person or an application) with its own credentials: a console password, access keys, MFA. |
| **Group** | A set of users. Policies attached to a group apply to every user in it. |
| **Role** | An identity that anyone allowed to can assume. It has temporary credentials and is not tied to one person. |
| **Managed policy** | A policy that can be attached to many users or groups. AWS or your administrators write it. If it changes, every identity it is attached to gets the change right away. |
| **Inline policy** | A policy that belongs to one user, group or role only. It is meant for one-off cases. |
| **Federation** | Lets existing company users reach AWS without creating an IAM user for each of them. |

### What a policy statement contains

- **Effect**: `Allow` or `Deny`.
- **Action**: the API calls the statement covers, for example `ec2:StopInstances` or `s3:List*`.
- **Resource**: what the statement applies to, for example one bucket ARN, or `*` for everything.

## Starting setup

| Users (no permissions, no groups) | Groups | Policy | Type |
| --- | --- | --- | --- |
| user-1 | S3-Support | `AmazonS3ReadOnlyAccess` | AWS managed |
| user-2 | EC2-Support | `AmazonEC2ReadOnlyAccess` | AWS managed |
| user-3 | EC2-Admin | `EC2-Admin-Policy` | Inline |

The policy documents are saved in [policies/](policies/) as YAML. The AWS managed ones are copies for reference. AWS may have updated its versions since.

- [AmazonS3ReadOnlyAccess.yaml](policies/AmazonS3ReadOnlyAccess.yaml): `Get`, `List` and `Describe` actions on S3.
- [AmazonEC2ReadOnlyAccess.yaml](policies/AmazonEC2ReadOnlyAccess.yaml): `Describe` and `List` actions on EC2, Elastic Load Balancing, CloudWatch and Auto Scaling. It allows viewing only, no changes.
- [EC2-Admin-Policy.yaml](policies/EC2-Admin-Policy.yaml): `ec2:Describe*`, plus `ec2:StartInstances` and `ec2:StopInstances`.

## Business scenario

| User | Group | Permissions |
| --- | --- | --- |
| user-1 | S3-Support | Read-only access to Amazon S3 |
| user-2 | EC2-Support | Read-only access to Amazon EC2 |
| user-3 | EC2-Admin | View, start and stop EC2 instances |

## Steps

### Task 1: Look at the users and groups

1. Go to **IAM → Users**. user-1 has a console password but no permissions and no groups.
2. Go to **IAM → User groups**. Open each group's **Permissions** tab and read its policy in the **JSON** view.

### Task 2: Add users to groups

In **IAM → User groups → *group* → Users → Add users**:

- S3-Support ← user-1
- EC2-Support ← user-2
- EC2-Admin ← user-3

Each group should now show **1** in the Users column.

The same thing with the AWS CLI:

```bash
aws iam add-user-to-group --group-name S3-Support  --user-name user-1
aws iam add-user-to-group --group-name EC2-Support --user-name user-2
aws iam add-user-to-group --group-name EC2-Admin   --user-name user-3

# Check the result
aws iam get-group --group-name S3-Support --query 'Users[].UserName'
```

### Task 3: Sign in as each user and test

Copy the **sign-in URL** from the IAM dashboard. It looks like `https://<account-id>.signin.aws.amazon.com/console`. Open it in a private browser window and sign in as each user in turn. Make sure the console is set to the lab's Region.

## Results

| User | Action | Expected result | Why |
| --- | --- | --- | --- |
| user-1 | List S3 buckets and the objects in the lab bucket | ✅ Allowed | `s3:List*` and `s3:Get*` |
| user-1 | View EC2 instances | ❌ No instances shown | No EC2 permissions |
| user-2 | View EC2 instances | ✅ Allowed | `ec2:Describe*` |
| user-2 | Stop an instance | ❌ "You are not authorized to perform this operation" | `ec2:StopInstances` is not granted |
| user-2 | Open S3 | ❌ Access Denied | No S3 permissions |
| user-3 | View EC2 instances | ✅ Allowed | `ec2:Describe*` |
| user-3 | Stop an instance | ✅ Instance goes to *stopping* | `ec2:StopInstances` is granted |

## Takeaways

- **Implicit deny by default.** A new IAM user can do nothing until a policy allows it.
- **Give permissions to groups, not to individual users.** To change what someone can do, move them to another group.
- **Least privilege.** Each person gets only the access their job needs. Support staff can view resources, and only the admin can change instance state.
- **Managed or inline.** Use managed policies for permission sets you reuse. Use inline policies for one-off, tightly scoped cases.
