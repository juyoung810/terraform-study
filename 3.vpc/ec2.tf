resource "aws_security_group" "allow_web-sg" {
  name        = "allow_web-sg"
  description = "Allow web-sg inbound traffic"
  vpc_id      = aws_vpc.juya-vpc-10-0-0-0.id # 생성한 vpc

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
    Name = "allow_web-sg"
  }
}

resource "aws_instance" "ju-bastion" {
  ami           = "ami-01d87646ef267ccd7"
  instance_type = "t2.micro"
  key_name = "tf-keypair-juya"
  vpc_security_group_ids = [aws_security_group.allow_web-sg.id]
  availability_zone = "ap-northeast-2a"
  subnet_id = aws_subnet.juya-sub-pub1-10-0-1-0.id
  user_data = file("./userdata.sh")

  root_block_device {
      volume_size = 30
  }
  tags = {
    Name = "ju-bastion"
  }
  
  
}
resource "aws_instance" "ju-web-2a" {
  ami           = "ami-01d87646ef267ccd7"
  instance_type = "t2.micro"
  key_name = "tf-keypair-juya"
  vpc_security_group_ids = [aws_security_group.allow_web-sg.id]
  availability_zone = "ap-northeast-2a"
  subnet_id = aws_subnet.juya-sub-pri1-10-0-3-0.id
  user_data = file("./userdata.sh")


  root_block_device {
      volume_size = 30
      volume_type = "gp2"
  }
  tags = {
    Name = "ju-web-2a"
  }
  
  
}
resource "aws_instance" "ju-web-2c" {
  ami           = "ami-01d87646ef267ccd7"
  instance_type = "t2.micro"
  key_name = "tf-keypair-juya"
  vpc_security_group_ids = [aws_security_group.allow_web-sg.id]
  availability_zone = "ap-northeast-2c"
  subnet_id = aws_subnet.juya-sub-pri2-10-0-4-0.id
  user_data = file("./userdata.sh")

  root_block_device {
      volume_size = 30
      volume_type = "gp2"
  }
  tags = {
    Name = "ju-web-2c"
  }
  
  
}
