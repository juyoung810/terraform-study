resource "aws_security_group" "alb-sg" { 
  name        = "alb-sg"
  description = "Allow alb inbound traffic"
  vpc_id = aws_vpc.juya-vpc-10-0-0-0.id # vpc.tf 에서 참조

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
    Name = "alb-sg"
  }
}
resource "aws_lb" "tf-alb" {
  name               = "tf-alb" 
  internal           = false 
  load_balancer_type = "application" 
  security_groups    = [aws_security_group.alb-sg.id]
# pub sub 1, 2를 참조하라 -> alb는 Public subnet에 배치한다.
  subnets = [aws_subnet.juya-sub-pub1-10-0-1-0.id,aws_subnet.juya-sub-pub2-10-0-2-0.id] 
  
  enable_deletion_protection = false 


  tags = {
    Name = "tf-alb" 
  }
}

resource "aws_lb_target_group" "alb-tg" {
  name     = "alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.juya-vpc-10-0-0-0.id
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 5
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 2
    unhealthy_threshold = 2
  }
}
resource "aws_lb_listener" "alb-ln" {
  load_balancer_arn = aws_lb.tf-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
}

resource "aws_lb_target_group_attachment" "foreach" {
  for_each = toset(data.aws_instances.test.ids) # 복수 개의 id들 이다.
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id        = each.value 
  port             = 80
}

data "aws_instances" "test" {
  instance_tags = {
    Name = "ju-web-*"
  }
}

# alb dns 이름 출력
output "alb_dns_name" {
  value = aws_lb.tf-alb.dns_name
}