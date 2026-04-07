# ==============================================================================
# Compute Module — Outputs
# ==============================================================================

output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.app[*].id
}

output "instance_public_ips" {
  description = "List of public IP addresses (empty if in private subnets)"
  value       = aws_instance.app[*].public_ip
}

output "instance_private_ips" {
  description = "List of private IP addresses"
  value       = aws_instance.app[*].private_ip
}

output "instance_details" {
  description = "Detailed information for each instance"
  value = {
    for idx, instance in aws_instance.app : instance.id => {
      instance_type     = instance.instance_type
      private_ip        = instance.private_ip
      public_ip         = instance.public_ip
      availability_zone = instance.availability_zone
      subnet_id         = instance.subnet_id
    }
  }
}

output "ami_id" {
  description = "AMI ID used for application instances"
  value       = data.aws_ami.ubuntu.id
}
