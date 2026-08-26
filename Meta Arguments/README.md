# Meta Arguments: `count`

## Purpose
Shows how Terraform's `count` meta-argument creates two instances of the same S3 bucket resource.

## Graph
```mermaid
flowchart LR
  V[bucket_name list] --> C[count = 2]
  C --> B0[aws_s3_bucket.my_bucket[0]]
  C --> B1[aws_s3_bucket.my_bucket[1]]
  S[S3 backend\ndev/terraform.tfstate] -. state .-> T[Terraform state]
```

## Run
```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
terraform state list
terraform destroy
```

The `bucket_name` list has three entries, but `count = 2`, so only indexes `0` and `1` are created. S3 names must be globally unique. The backend bucket must already exist before `terraform init`.

## Caveats
This example declares AWS `~> 6.0` but has no provider block, so region and credentials come from CLI/environment defaults. The backend key is shared by other learning folders; change it to a unique project key before use. There is no encryption, versioning, public-access block, or output.
