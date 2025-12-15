provider "aws" {
  region = "eu-west-1"
}

# ---------------------------
# IAM Role pour EC2 Monitoring
# ---------------------------
resource "aws_iam_role" "prometheus_role" {
  name = "prometheus-ec2-sd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy" "prometheus_policy" {
  name = "prometheus-ec2-sd-policy"
  role = aws_iam_role.prometheus_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["ec2:DescribeInstances","ec2:DescribeTags"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "prometheus_profile" {
  name = "prometheus-instance-profile"
  role = aws_iam_role.prometheus_role.name
}

# ---------------------------
# Security Groups
# ---------------------------
# Monitoring
resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring-sg"
  description = "Allow SSH, Grafana, Prometheus"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Applications
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow Node Exporter from Monitoring"

  ingress {
    from_port                = 9100
    to_port                  = 9100
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.monitoring_sg.id
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# Key Pair
# ---------------------------
resource "aws_key_pair" "monitoring_key" {
  key_name   = "monitoring-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# ---------------------------
# EC2 Monitoring
# ---------------------------
resource "aws_instance" "monitoring" {
  ami                         = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.monitoring_key.key_name
  security_groups             = [aws_security_group.monitoring_sg.name]
  iam_instance_profile        = aws_iam_instance_profile.prometheus_profile.name
  associate_public_ip_address = true

  user_data = file("monitoring/setup-monitoring.sh")

  tags = {
    Name        = "monitoring-server"
    Environment = "prod"
  }
}

# ---------------------------
# Launch Template pour App EC2
# ---------------------------
resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-lt-"
  image_id      = "ami-yyyyyyyyyyyy" # AMI de votre application
  instance_type = "t3.micro"
  key_name      = aws_key_pair.monitoring_key.key_name
  security_group_names = [aws_security_group.app_sg.name]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "app-instance"
      Environment = "prod"
    }
  }
}

# ---------------------------
# Auto Scaling Group pour les EC2 applicatives
# ---------------------------
resource "aws_autoscaling_group" "app_asg" {
  name                      = "app-asg"
  max_size                  = 5
  min_size                  = 2
  desired_capacity          = 2
  vpc_zone_identifier       = ["subnet-xxxxxxxx"] # à adapter
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Environment"
    value               = "prod"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }

  health_check_type = "EC2"
}
