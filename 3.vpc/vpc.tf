# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2"
}
# 1. Custom VPC 생성
resource "aws_vpc" "juya-vpc-10-0-0-0" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  # enable_dns_support 는 default 가 true

  tags = {
    Name = "juya-vpc-10-0-0-0"
  }
}
# 2. Public subnet 및 Private subnet 생성
# 2-1) Public subnet CIDR : 10.0.1.0/24, 10.0.2.0/24
resource "aws_subnet" "juya-sub-pub1-10-0-1-0" { 
  vpc_id     = aws_vpc.juya-vpc-10-0-0-0.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a" # 1. subnet 어느 가용 영역에 배치?
  map_public_ip_on_launch = true # 2.인스턴스 실행될 때 public ip 할당 받도록 하겠다.(option)

  tags = {
    Name = "juya-sub-pub1-10-0-1-0"
  }
}
resource "aws_subnet" "juya-sub-pub2-10-0-2-0" { 
  vpc_id     = aws_vpc.juya-vpc-10-0-0-0.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-2c" # 1. subnet 어느 가용 영역에 배치?
  map_public_ip_on_launch = true # 2.인스턴스 실행될 때 public ip 할당 받도록 하겠다.(option)

  tags = {
    Name = "juya-sub-pub2-10-0-2-0"
  }
}

#2-2) Private subnet CIDR : 10.0.3.0/24, 10.0.4.0/24
resource "aws_subnet" "juya-sub-pri1-10-0-3-0" { 
  vpc_id     = aws_vpc.juya-vpc-10-0-0-0.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2a" # 1. subnet 어느 가용 영역에 배치?
  #map_public_ip_on_launch = true # 2.인스턴스 실행될 때 public ip 할당 받도록 하겠다.(option) -> private 에서는 의미 없음

  tags = {
    Name = "juya-sub-pri1-10-0-3-0"
  }
}
resource "aws_subnet" "juya-sub-pri2-10-0-4-0" { 
  vpc_id     = aws_vpc.juya-vpc-10-0-0-0.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-northeast-2c" # 1. subnet 어느 가용 영역에 배치?
  #map_public_ip_on_launch = true # 2.인스턴스 실행될 때 public ip 할당 받도록 하겠다.(option) -> private 에서는 의미 없음

  tags = {
    Name = "juya-sub-pri2-10-0-4-0"
  }
}

#3. Internet gateway 생성
resource "aws_internet_gateway" "igw-juya-vpc-10-0-0-0" { # 어떤 vpc 와 연결할건지 명시해주는게 좋음
  vpc_id = aws_vpc.juya-vpc-10-0-0-0.id

  tags = {
    Name = "igw-juya-vpc-10-0-0-0"
  }
}
# 4. Route table 생성 및 associate
# 4-1) public 1개
resource "aws_route_table" "rt-pub-juya-vpc-10-0-0-0" { # public 용 하나 생성, vpc 명시
  vpc_id = aws_vpc.juya-vpc-10-0-0-0.id

  route {
    cidr_block = "0.0.0.0/0" # 모든 routing은 internet gateway 로 가라
    gateway_id = aws_internet_gateway.igw-juya-vpc-10-0-0-0.id
  }

  tags = {
    Name = "rt-pub-juya-vpc-10-0-0-0"
  }
}
#  rout table 잘 작동하는 지 확인하기 위해 associate
resource "aws_route_table_association" "rt-pub-as1-juya-vpc-10-0-0-0" {
  subnet_id      = aws_subnet.juya-sub-pub1-10-0-1-0.id
  route_table_id = aws_route_table.rt-pub-juya-vpc-10-0-0-0.id
}
resource "aws_route_table_association" "rt-pub-as2-juya-vpc-10-0-0-0" {
  subnet_id      = aws_subnet.juya-sub-pub2-10-0-2-0.id
  route_table_id = aws_route_table.rt-pub-juya-vpc-10-0-0-0.id # 퍼블릭용 라우팅 테이블 사용
}
# 4-2) private 1,2 2개
# 2개 만드는 이유 : private subnet 에 만드는 ec2가 인터넷 통신 위해서는 not to gateway 라우팅 필요
# 가용 영역 2a, 2c에 각각 not to gateway 가 fail over 구성이기 때문
# private routing table 2개 만들어 not to gateway 2a, 2c 에 맞춰지는 것
resource "aws_route_table" "rt-pri1-juya-vpc-10-0-0-0" { # public 용 하나 생성, vpc 명시
  vpc_id = aws_vpc.juya-vpc-10-0-0-0.id
/* not to gateway 참조하라 */
  route {
    cidr_block = "0.0.0.0/0" # 모든 routing은 internet gateway 로 가라
    gateway_id = aws_nat_gateway.natgw-2a.id
  }
  tags = {
    Name = "rt-pri1-juya-vpc-10-0-0-0"
  }
}
resource "aws_route_table" "rt-pri2-juya-vpc-10-0-0-0" { # public 용 하나 생성, vpc 명시
  vpc_id = aws_vpc.juya-vpc-10-0-0-0.id
  route {
    cidr_block = "0.0.0.0/0" # 모든 routing은 internet gateway 로 가라
    gateway_id = aws_nat_gateway.natgw-2c.id
  }
  tags = {
    Name = "rt-pri2-juya-vpc-10-0-0-0"
  }
}
resource "aws_route_table_association" "rt-pri1-as1-juya-vpc-10-0-0-0" {
  subnet_id      = aws_subnet.juya-sub-pri1-10-0-3-0.id
  route_table_id = aws_route_table.rt-pri1-juya-vpc-10-0-0-0.id
}
resource "aws_route_table_association" "rt-pri2-as2-juya-vpc-10-0-0-0" {
  subnet_id      = aws_subnet.juya-sub-pri2-10-0-4-0.id
  route_table_id = aws_route_table.rt-pri2-juya-vpc-10-0-0-0.id # 퍼블릭용 라우팅 테이블 사용
}
# 5. Elastic IP 및 NAT Gateway 생성
# 5-1)
resource "aws_eip" "nat-2a" {
  vpc      = true
}
resource "aws_eip" "nat-2c" {
  vpc      = true
}
# 5-2) NAT Gateway
resource "aws_nat_gateway" "natgw-2a" {
  allocation_id = aws_eip.nat-2a.id
  subnet_id     = aws_subnet.juya-sub-pub1-10-0-1-0.id

  tags = {
    Name = "gw NAT-2a"
  }
  
}
resource "aws_nat_gateway" "natgw-2c" {
  allocation_id = aws_eip.nat-2c.id
  subnet_id     = aws_subnet.juya-sub-pub2-10-0-2-0.id

  tags = {
    Name = "gw NAT-2c"
  }
  
}
# 6. ec2 생성 - EC2 bastion, private subnet 1, private subnet 2에 하나씩
