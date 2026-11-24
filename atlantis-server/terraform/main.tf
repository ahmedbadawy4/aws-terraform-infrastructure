data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_security_group" "atlantis_sg" {
  name        = "atlantis_sg"
  description = "Allow HTTP for Atlantis webhooks and SSH for Ansible"

  ingress {
    description = "Atlantis webhooks and UI"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.sg_cidr_blocks
  }

  ingress {
    description = "SSH for Ansible"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "atlantis" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  iam_instance_profile        = aws_iam_instance_profile.atlantis_profile.name
  vpc_security_group_ids      = [aws_security_group.atlantis_sg.id]
  associate_public_ip_address = true

  # IMDSv2 only. Hop limit 2 lets the Atlantis container read the instance role credentials.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    encrypted   = true
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "atlantis-${var.environment}"
  }

  # A newer Amazon Linux image must not replace a running server.
  lifecycle {
    ignore_changes = [ami]
  }
}
