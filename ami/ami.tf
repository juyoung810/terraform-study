# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2"
}
data "aws_instances" "test" {
  instance_tags = {
    Name = "ju-web-*"
  }
}
resource "aws_ami_from_instance" "ju-example" { # 복수개의 instance 읽어와서 custom ami 생성하기
  for_each = toset(data.aws_instances.test.ids)
  name               = each.value
  source_instance_id = each.value
  tags = {
    Name = "ju-web-${each.key}" # name 가져오게 된다.
  }
}