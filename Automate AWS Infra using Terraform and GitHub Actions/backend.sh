# Create bucket for Terraform state
aws s3 mb s3://2360476128401834561 --region us-east-1

# Enable versioning for state history
aws s3api put-bucket-versioning \
  --bucket 2360476128401834561 \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket 2360476128401834561 \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'