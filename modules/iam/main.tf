# ==============================================================================
# IAM Module — Users, Groups, and Policies
# ==============================================================================
# Manages IAM identity lifecycle: creates users, organizes them into groups,
# and attaches least-privilege policies. Supports both group-attached and
# user-specific policy assignments.
# ==============================================================================

data "aws_caller_identity" "current" {}

# --- IAM Users ---
resource "aws_iam_user" "this" {
  for_each = toset(var.iam_users)

  name          = "${each.value}-${var.environment}"
  force_destroy = var.environment != "prod" # Prevent accidental prod user deletion

  tags = merge(var.common_tags, {
    Name        = each.value
    Environment = var.environment
  })
}

# --- IAM Group ---
resource "aws_iam_group" "this" {
  name = "${var.group_name}-${var.environment}"
}

# --- Group Membership ---
resource "aws_iam_group_membership" "this" {
  name  = "${var.group_name}-membership-${var.environment}"
  group = aws_iam_group.this.name
  users = [for user in var.users_in_group : aws_iam_user.this[user].name]
}

# --- Group Policy — S3 Read Access (Least Privilege) ---
resource "aws_iam_group_policy" "group_policy" {
  name  = "${var.group_policy_name}-${var.environment}"
  group = aws_iam_group.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*",
          "arn:aws:s3:::${var.project_name}-*/*"
        ]
      }
    ]
  })
}

# --- Individual User Policy — EC2 Describe (Read-Only, Not Full Access) ---
resource "aws_iam_user_policy" "independent_user_policy" {
  name = "${var.user_policy_name}-${var.environment}"
  user = aws_iam_user.this[var.independent_user].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2ReadAccess"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:List*"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- Login Profiles (Console Access) ---
resource "aws_iam_user_login_profile" "this" {
  for_each = aws_iam_user.this

  user                    = each.value.name
  password_reset_required = true
}

# --- Access Keys (Programmatic Access) ---
resource "aws_iam_access_key" "this" {
  for_each = aws_iam_user.this

  user       = each.value.name
  depends_on = [aws_iam_user_login_profile.this]
}
