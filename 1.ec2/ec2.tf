# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2"
}
variable "subnet_id" {
  default = ["subnet-033fcb86690c20369","subnet-097b40615c674f993"]
}
variable "vpc_id" {
  default = "vpc-0312d1996462eb0a0"
}
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "web from VPC"
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
    Name = "allow_web"
  }
}

resource "aws_instance" "ju-web-2c" {
  ami           = "ami-01d87646ef267ccd7"
  instance_type = "t2.micro"
  key_name = "tf-keypair-juya"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  availability_zone = "ap-northeast-2c"
  subnet_id = var.subnet_id[0]
  user_data = file("./init-script.sh")

  root_block_device {
      volume_size = 30
      volume_type = "gp2"
  }
  tags = {
    Name = "ju-web-2c"
  }
  
  
}
resource "aws_instance" "ju-web-2a" {
  ami           = "ami-01d87646ef267ccd7"
  instance_type = "t2.micro"
  key_name = "tf-keypair-juya"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  availability_zone = "ap-northeast-2a"
  subnet_id = var.subnet_id[1]
  user_data = file("./init-script.sh")

  root_block_device {
      volume_size = 30
      volume_type = "gp2"
  }
  tags = {
    Name = "ju-web-2a"
  }
  
  
}