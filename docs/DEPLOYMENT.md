# Deployment Guide

## Prerequisites

Before deploying, ensure you have:

1. **Terraform** >= 1.5.0 installed
   ```bash
   terraform --version
   ```

2. **AWS CLI** installed and configured
   ```bash
   aws --version
   aws configure  # Set access key, secret key, region
   # OR use named profiles:
   export AWS_PROFILE=your-profile
   ```

3. **EC2 Key Pair** created in your target region
   ```bash
   aws ec2 create-key-pair --key-name aws-infra-key --query 'KeyMaterial' --output text > aws-infra-key.pem
   chmod 400 aws-infra-key.pem
   ```

4. **Sufficient IAM permissions** for the deploying user:
   - `ec2:*`, `rds:*`, `iam:*`, `s3:*`, `dynamodb:*`
   - Or use an admin role for initial deployment

## Step 1: Bootstrap Remote State Backend

This only needs to be done **once** per AWS account.

```bash
# From the project root
chmod +x scripts/bootstrap-backend.sh
./scripts/bootstrap-backend.sh us-east-1 aws-infra-platform
```

This creates:
- S3 bucket `aws-infra-platform-tfstate` (versioned, encrypted, public access blocked)
- DynamoDB table `aws-infra-platform-tflock` (state locking)

> **Note**: If you want to skip remote state for testing, comment out the `backend.tf` file in your chosen environment.

## Step 2: Configure Environment Variables

```bash
cd environments/dev  # or staging, or prod

# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
```

**Required values:**
- `key_name` — Your EC2 key pair name
- `db_password` — A strong database password (8+ characters)
- `admin_cidr_blocks` — Your IP address in CIDR notation (e.g., `["203.0.113.5/32"]`)

## Step 3: Initialize Terraform

```bash
cd environments/dev
terraform init
```

Expected output:
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

## Step 4: Validate Configuration

```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

## Step 5: Review Execution Plan

```bash
terraform plan -out=tfplan
```

Review the plan carefully. You should see resources being created for:
- 1 VPC, 4 subnets, 1 IGW, 1 NAT Gateway, route tables
- 3 security groups (bastion, app, db)
- 1 bastion host (EC2)
- 1 application server (EC2)
- 1 RDS MySQL instance
- 3 IAM users, 1 group, policies

## Step 6: Deploy

```bash
terraform apply tfplan
```

> ⏱️ **Expected time**: 10-15 minutes (RDS creation takes the longest)

## Step 7: Verify Deployment

```bash
# View all outputs
terraform output

# Verify bastion connectivity
terraform output bastion_ssh_command
# Copy the SSH command and test it

# Verify RDS endpoint
terraform output db_endpoint

# Verify IAM users
terraform output iam_users

# View sensitive credentials
terraform output -json iam_user_credentials | jq .
```

### AWS Console Verification Checklist

- [ ] **VPC**: Check VPC dashboard → your VPC with correct CIDR
- [ ] **Subnets**: 2 public + 2 private subnets in different AZs
- [ ] **EC2**: Bastion in public subnet, app server in private subnet
- [ ] **RDS**: MySQL instance in private subnet, correct Multi-AZ setting
- [ ] **IAM**: 3 users created, 1 group with 2 members
- [ ] **Security Groups**: 3 groups with correct inbound rules

## Step 8: Test Connectivity

```bash
# SSH to bastion
ssh -i your-key.pem ubuntu@<bastion-public-ip>

# From bastion, SSH to app server
ssh -i your-key.pem ubuntu@<app-private-ip>

# From bastion or app server, test DB connectivity
mysql -h <rds-endpoint> -u admin -p
```

## Deploying Additional Environments

```bash
# Staging
cd environments/staging
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Production (review plan carefully!)
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — ensure admin_cidr_blocks is restricted!
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Teardown

```bash
# Destroy dev environment
cd environments/dev
terraform destroy

# For production (deletion protection must be disabled first):
# 1. Set deletion_protection = false in database module
# 2. terraform apply
# 3. terraform destroy
```

> ⚠️ **Warning**: `terraform destroy` deletes ALL resources in the environment. Always verify you're in the correct environment directory.
