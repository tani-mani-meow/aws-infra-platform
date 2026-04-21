# ==============================================================================
# Development Environment — Variables
# ==============================================================================

# --- General ---
variable "project_name" {
  description = "Project name used across all resources"
  type        = string
  default     = "aws-infra-platform"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Owner tag for resource identification"
  type        = string
  default     = "devops-team"
}

# --- Networking ---
variable "vpc_cidr" {
  description = "CIDR block for the development VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for dev environment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed SSH access to bastion (restrict to your IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # ⚠️ Replace with your IP in production
}

# --- SSH ---
variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

# --- Database ---
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

# --- IAM ---
variable "iam_users" {
  description = "List of IAM users to create"
  type        = list(string)
  default     = ["dev-user-1", "dev-user-2", "dev-user-3"]
}

variable "iam_group_name" {
  description = "IAM group name"
  type        = string
  default     = "developers"
}

variable "users_in_group" {
  description = "Users to add to the IAM group"
  type        = list(string)
  default     = ["dev-user-1", "dev-user-2"]
}

variable "independent_user" {
  description = "User that remains outside the group"
  type        = string
  default     = "dev-user-3"
}
