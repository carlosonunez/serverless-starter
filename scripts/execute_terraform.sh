#!/usr/bin/env sh
source $(dirname "$0")/helpers/shared_secrets.sh
TERRAFORM_STATE_S3_KEY="${TERRAFORM_STATE_S3_KEY?Please provide a S3 key to store TF state in.}"
TERRAFORM_STATE_S3_BUCKET="${TERRAFORM_STATE_S3_BUCKET?Please provide a S3 bucket to store state in.}"
AWS_REGION="${AWS_REGION?Please provide an AWS region.}"

set -e
action=$1
shift
app_account_name=$(cat ./config.yml | \
  grep "project:" | \
  cut -f2 -d : | \
  tr -d ' ')
if test -z "$app_account_name"
then
  >&2 echo "ERROR: Please define your project name in config.yml."
  exit 1
fi

export TF_VAR_app_account_name="$app_account_name"


terraform init --backend-config="bucket=${TERRAFORM_STATE_S3_BUCKET}" \
  --backend-config="key=${TERRAFORM_STATE_S3_KEY}" \
  --backend-config="region=$AWS_REGION" && \

terraform $action $* && \
  if [ "$action" == "apply" ]
  then
    mkdir -p ./secrets
    secrets=$(terraform output)
    for output_var in app_account_ak app_account_sk certificate_arn bucket_name
    do
      value=$(echo "$secrets" | grep -E "^$output_var" | cut -f2 -d = | sed 's/^ //')
      write_secret "$value" "$output_var"
    done
  elif [ "$action" == "destroy" ]
  then
    rm -rf ./secrets
  fi
