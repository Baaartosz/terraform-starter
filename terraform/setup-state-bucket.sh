#!/bin/bash

# Function to print messages in green
function print_success {
  echo -e "\033[0;32m$1\033[0m"
}

# Function to print messages in red
function print_error {
  echo -e "\033[0;31m$1\033[0m"
}

# Function to print messages in blue
function print_info {
  echo -e "\033[0;34m$1\033[0m"
}

# Ensure AWS_PROFILE, BUCKET_NAME, and BUCKET_REGION are provided
if [ $# -ne 3 ]; then
  print_error "Usage: $0 <AWS_PROFILE> <BUCKET_NAME> <BUCKET_REGION>"
  exit 1
fi

AWS_PROFILE=$1
BUCKET_NAME=$2
BUCKET_REGION=$3

# Set the AWS profile for the session
export AWS_PROFILE="$AWS_PROFILE"

# Check if AWS_PROFILE is set
if [ -z "$AWS_PROFILE" ]; then
  print_error "Error: AWS_PROFILE is not set."
  exit 1
fi

# Check if the bucket already exists
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
  print_info "Creating S3 bucket $BUCKET_NAME in region $BUCKET_REGION..."

  # Create the S3 bucket
  if aws s3 mb s3://"$BUCKET_NAME" --region "$BUCKET_REGION"; then
    print_success "Bucket $BUCKET_NAME created successfully."
  else
    print_error "Failed to create bucket $BUCKET_NAME."
    exit 1
  fi
else
  print_error "Bucket $BUCKET_NAME already exists."
  exit 1
fi

# Enable versioning on the bucket
print_info "Enabling versioning on bucket $BUCKET_NAME..."
if aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled; then
  print_success "Versioning enabled successfully."
else
  print_error "Failed to enable versioning."
  exit 1
fi

# Enable encryption on the bucket
print_info "Enabling encryption on bucket $BUCKET_NAME..."
if aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'; then
  print_success "Encryption enabled successfully."
else
  print_error "Failed to enable encryption."
  exit 1
fi

print_success "Finished creating and configuring $BUCKET_NAME in $BUCKET_REGION"
