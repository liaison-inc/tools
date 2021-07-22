#!/bin/bash

if ! command -v jq &>/dev/null; then
  echo "jq could not be found"
  exit
fi

if ! command -v aws &>/dev/null; then
  echo "aws could not be found"
  exit
fi

FILE_NAME="terraform.auto.tfvars.json"
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  -p | --profile)
    AWS_PROFILE="$2"
    shift
    ;;
  -r | --region)
    AWS_REGION="$2"
    shift
    ;;
  -n | --name)
    FILE_NAME="$2"
    shift
    ;;
  -f | --force)
    FORCE=true
    shift
    ;;
  esac
  shift
done

if [ -f "$FILE_NAME" ] && [ "$FORCE" != true ]; then
  exit 0
fi

if [[ -z $AWS_PROFILE ]]; then
  echo "Please pass in a configured AWS profile (-p or --profile)"
  exit 1
fi

AWS_ACCESS_KEY_ID=$(aws --profile "${AWS_PROFILE}" configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws --profile "${AWS_PROFILE}" configure get aws_secret_access_key)
AWS_DEFAULT_REGION=$(aws --profile "${AWS_PROFILE}" configure get region)

if [[ -n $AWS_REGION ]]; then
  AWS_DEFAULT_REGION=${AWS_REGION}
fi

JSON=$(
  echo "{}" |
    jq --arg AWS_ACCESS_KEY_ID "$AWS_ACCESS_KEY_ID" \
      --arg AWS_SECRET_ACCESS_KEY "$AWS_SECRET_ACCESS_KEY" \
      --arg AWS_DEFAULT_REGION "$AWS_DEFAULT_REGION" \
      '{
        "AWS_ACCESS_KEY_ID": $AWS_ACCESS_KEY_ID,
        "AWS_SECRET_ACCESS_KEY": $AWS_SECRET_ACCESS_KEY,
        "AWS_DEFAULT_REGION": $AWS_DEFAULT_REGION
      }'
)

echo "$JSON" | jq '.' >./"$FILE_NAME"
