# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2"
}
resource "aws_key_pair" "terraform-key-pair" {
  key_name   = "tf-keypair-juya"
  public_key = file("/home/ec2-user/.ssh/tf-keypair-juya.pub")
  
}