# Security group for bastion
resource "aws_security_group" "bastion_sg" {
  name_prefix = "${var.name}-bastion-"
  description = "${var.name} bastion"
  vpc_id = "${var.vpc_id}"

  # Allow SSH ingress
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    # Whitelisting only
    cidr_blocks = ["0.0.0.0/32"]
  }

  # Allow all egress
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Bastion Launch Configuration
resource "aws_launch_configuration" "bastion_lc" {
  name_prefix          = "${var.name}-bastion-"
  image_id             = "${var.ami}"
  instance_type        = "${var.instance_type}"
  security_groups      = ["${aws_security_group.bastion_sg.id}"]
  key_name             = "${var.key_name}"
  associate_public_ip_address = "true"
  user_data = "${file("dependencies/install_python.sh")}"

  lifecycle {
    create_before_destroy = "true"
  }
}

# Bastion Auto-Scaling Group
resource "aws_autoscaling_group" "bastion_asg" {
  name                 = "${var.name}-bastion"
  max_size             = 1
  min_size             = 1
  desired_capacity     = 1
  launch_configuration = "${aws_launch_configuration.bastion_lc.name}"
  vpc_zone_identifier  = var.subnet_ids

  dynamic "tag" {
    for_each = merge({
      "Name" = "${var.name}-bastion"
    }, var.tags)

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}