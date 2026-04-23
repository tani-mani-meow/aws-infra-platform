terraform {
  backend "s3" {
    bucket         = "aws-infra-platform-tfstate"
    key            = "environments/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "aws-infra-platform-tflock"
    encrypt        = true
  }
}
