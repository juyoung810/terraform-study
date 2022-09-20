# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2"
}

# 1. 보안 그룹 생성
resource "aws_security_group" "allow_alb" { # 현업에서는 ec2 용 보안 그룹,alb 용 등 용도에 맞게 사용하는 것 권장
  name        = "allow_alb"
  description = "Allow alb inbound traffic"
  vpc_id      = "vpc-0312d1996462eb0a0"

  ingress {
    description      = "alb from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1" 
    cidr_blocks      = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_alb_juya"
  }
}
resource "aws_lb" "test" {
  name               = "test-lb-tf-juya" # 실제 콘솔에 보이는 이름
  internal           = false # 인터넷용
  load_balancer_type = "application" # application load balancer
  security_groups    = [aws_security_group.allow_alb.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "test-lb"
    enabled = true
  }

  tags = {
    Environment = "production"
  }
}