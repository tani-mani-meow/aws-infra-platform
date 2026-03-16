# ==============================================================================
# Security Module — Outputs
# ==============================================================================

output "bastion_security_group_id" {
  description = "Security group ID for bastion host"
  value       = aws_security_group.bastion.id
}

output "application_security_group_id" {
  description = "Security group ID for application servers"
  value       = aws_security_group.application.id
}

output "database_security_group_id" {
  description = "Security group ID for RDS database"
  value       = aws_security_group.database.id
}

output "security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    bastion     = aws_security_group.bastion.id
    application = aws_security_group.application.id
    database    = aws_security_group.database.id
  }
}
