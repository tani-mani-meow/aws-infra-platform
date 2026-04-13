# ==============================================================================
# Compute Module — EC2 Application Servers
# ==============================================================================
# Provisions EC2 instances in private subnets with templatized user data.
# Uses dynamic AMI lookup for always-current OS images.
# ==============================================================================

# --- Latest Ubuntu 22.04 AMI (auto-discovered) ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# --- Application EC2 Instances ---
resource "aws_instance" "app" {
  count = var.instance_count

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  user_data = var.db_endpoint != "" ? templatefile("${path.module}/templates/userdata.sh.tpl", {
    db_endpoint = var.db_endpoint
    db_name     = var.db_name
    db_username = var.db_username
    db_password = var.db_password
    environment = var.environment
  }) : null

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens   = "required" # IMDSv2 enforced
    http_endpoint = "enabled"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-${count.index + 1}-${var.environment}"
    Role = "application"
  })
}
