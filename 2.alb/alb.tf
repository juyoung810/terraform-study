# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2"
}
# 2-2) variable block 으로 vpc, subnet id 설정
variable "vpc_id" {
  default = "vpc-0312d1996462eb0a0"
}

variable "subnet_id" {
  default = ["subnet-097b40615c674f993","subnet-033fcb86690c20369"]
}

# 2-3) data source로 설정 -> aws 의 정보를 받아오도록
/*
aws의 vpcs 에서 foo 라는 이름으로 정보를 읽어오겠다.
기존에 aws에서 vpc 한 개 인데, vpcs는 복수 이므로 매치 되지 않아 오류 발생

data "aws_subnet_ids" "example" {
 vpc_id = data.aws_vpcs.foo.id
}
output "vpc_id" {
  value = data.aws_vpcs.foo.id
}
-> aws_vpc 로 변경
*/
data "aws_vpc" "foo" { # -> 우리는 현재 2개라 태그 추가
   tags = {
    Name = "default"
  }
} 

data "aws_subnet_ids" "example" {
 # vpc_id = var.vpc_id
 vpc_id = data.aws_vpc.foo.id
}

data "aws_subnet" "example" {
  for_each = data.aws_subnet_ids.example.ids # 반복 순환문으로 받아온다
  id       = each.value
}

output "subnet_cidr_blocks" {
  value = [for s in data.aws_subnet.example : s.cidr_block] # 반복 순환문으로 출력
}

# 5-2) alb dns 이름 출력 -> alb 에 ec2 인스턴스 정상적으로 등록되면, 인스턴스 아이디 보여주는 웹페이지로 연결됨
output "alb_dns_name" {
  value = aws_lb.test.dns_name
}
# 1. 보안 그룹 생성
resource "aws_security_group" "allow_alb" { # 현업에서는 ec2 용 보안 그룹,alb 용 등 용도에 맞게 사용하는 것 권장
  name        = "allow_alb"
  description = "Allow alb inbound traffic"
  #vpc_id      = "vpc-0312d1996462eb0a0" 
  vpc_id = var.vpc_id # 2-2

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
  
  # 2.가용 영역 2a, 2c의 subnet id 직접 입력 -> alb 에서 subnet 인식
  #subnets            = ["subnet-097b40615c674f993","subnet-033fcb86690c20369"] 
  #subnets           = var.subnet_id #2-2 -> 2개의 서브넷 아이디 참조하겠다.
  subnets = data.aws_subnet_ids.example.ids

  enable_deletion_protection = false # alb 삭제되지 않도록 보호 , true 하면 tf destroy 안됨


  tags = {
    Name = "juya_alb" 
  }
}

# 3. instance type의 target group
resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   =  data.aws_vpc.foo.id
  # 3-1)instance type이 defatult 라 추가해놓은 것이 없으면 instance type
  target_type = "ip" 
  # 3-2) Ip tye
  
  # health_check 추가 필요
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
# 4. 타켓그룹으로 트래픽 훑게 만들 listener 추가
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}

# 5.  Target group attachment (IP 타입)
# 5-1) IP 직접 각각 attach
/*
resource "aws_lb_target_group_attachment" "test-2c" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = data.aws_instances.test.private_ips[0] # ec2 instance의 private ip 뭐냐(argument 보기)  -> alb 에 넣기
  port             = 80
}
resource "aws_lb_target_group_attachment" "test-2a" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = data.aws_instances.test.private_ips[1] # ec2 instance의 private ip 뭐냐(argument 보기)  -> alb 에 넣기
  port             = 80
}*/
# 5-2 ) ec2 instance 많이 늘어나면 그만큼 코드 늘어남 -> for each 문으로 절약
/*
resource "aws_lb_target_group_attachment" "test-2a" {
  for_each = toset(data.aws_instances.test.private_ips) # 반복 순환문으로 받아온다 -> map 이나 string set으로 ..map 형식 함수 사용
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = each.value # 받아온 값을 넣어준다.
  port             = 80
}
*/
# 5-3) Loop 순환문(count-index)
resource "aws_lb_target_group_attachment" "test-2a" {
  count = length(data.aws_instances.test.private_ips) # 전체 인수 값 count라는 변수에 받아옴
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = element(data.aws_instances.test.private_ips,count.index) # count 의 index에 따라 값 받아온다.
  port             = 80
}
data "aws_instances" "test" {
  instance_tags = {
    Name = "ju-web-*" # ju-web-2a, ju-web-2c
  }
}