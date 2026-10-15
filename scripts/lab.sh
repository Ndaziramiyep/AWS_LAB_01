#!/usr/bin/env bash
# AWS Lab 01 - Introduction to IAM
#
# Usage:
#   ./scripts/lab.sh deploy <password>   Create everything from templates/iam-lab.yaml (your own account)
#   ./scripts/lab.sh groups              Task 2 only: add the existing lab users to the existing lab groups
#   ./scripts/lab.sh test                Check each user's permissions with the IAM policy simulator
#   ./scripts/lab.sh outputs             Show the sign-in URL, bucket name and instance ID
#   ./scripts/lab.sh delete              Delete the stack and everything it created
#
# Needs the AWS CLI v2, configured with credentials (aws configure).
# Region comes from AWS_REGION / your CLI profile; override with: AWS_REGION=us-east-1 ./scripts/lab.sh ...

set -euo pipefail

STACK_NAME="${STACK_NAME:-iam-lab-01}"
TEMPLATE="$(cd "$(dirname "$0")/.." && pwd)/templates/iam-lab.yaml"

deploy() {
  local password="${1:?Usage: $0 deploy <password>}"
  aws cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --template-file "$TEMPLATE" \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides UserPassword="$password"
  outputs
}

# The lab environment already has the users and groups, so only Task 2 is needed there.
groups() {
  aws iam add-user-to-group --group-name S3-Support  --user-name user-1
  aws iam add-user-to-group --group-name EC2-Support --user-name user-2
  aws iam add-user-to-group --group-name EC2-Admin   --user-name user-3
  for g in S3-Support EC2-Support EC2-Admin; do
    echo "$g: $(aws iam get-group --group-name "$g" --query 'Users[].UserName' --output text)"
  done
}

# Asks IAM whether each user would be allowed each action, without signing in as them.
test_permissions() {
  local account
  account="$(aws sts get-caller-identity --query Account --output text)"
  local actions="s3:ListAllMyBuckets s3:GetObject ec2:DescribeInstances ec2:StopInstances ec2:StartInstances"

  for user in user-1 user-2 user-3; do
    echo "== $user"
    # shellcheck disable=SC2086
    aws iam simulate-principal-policy \
      --policy-source-arn "arn:aws:iam::${account}:user/${user}" \
      --action-names $actions \
      --query 'EvaluationResults[].[EvalActionName,EvalDecision]' \
      --output text
  done
}

outputs() {
  aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' --output table
}

delete() {
  local bucket
  bucket="$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)"
  # CloudFormation cannot delete a bucket that still has objects in it.
  [ -n "$bucket" ] && aws s3 rm "s3://$bucket" --recursive
  aws cloudformation delete-stack --stack-name "$STACK_NAME"
  aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME"
  echo "Stack $STACK_NAME deleted."
}

case "${1:-}" in
  deploy)  shift; deploy "$@" ;;
  groups)  groups ;;
  test)    test_permissions ;;
  outputs) outputs ;;
  delete)  delete ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
