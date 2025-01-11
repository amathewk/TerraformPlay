variable "port" {
  type = number
  default = 8080
  description = "port"
}

#output "ipaddr" {
#  value = aws_instance.example.public_ip
#}

resource "aws_launch_configuration" "example" {
  image_id           = "ami-07ba8005cde2a7dc9"
  instance_type = "t2.micro"
  
  user_data = <<-EOF
    #! /bin/bash
    echo "Hello!" > index.html
    nohup busybox httpd -f -p ${var.port} &
  EOF
  
  security_groups = [aws_security_group.instance.id]
  
#  vpc_security_group_ids = [aws_security_group.instance.id]
  
#  user_data_replace_on_change = true
  
#  tags = {
#    Name = "terraform-example"
#  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  max_size = 5
  min_size = 2

  launch_configuration = aws_launch_configuration.example
  vpc_zone_identifier = data.aws_subnets.default.ids
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "terraform-asg-example"
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  
  ingress {
    from_port = var.port
    protocol  = "tcp"
    to_port   = var.port
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc_id"
    values = [data.aws_vpc.default.id]
  }
}