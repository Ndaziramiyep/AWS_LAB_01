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

