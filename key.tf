resource "aws_key_pair" "ec2_key" {
  key_name = "eks-key"
  public_key = "ADD PUBLIC KEY HERE"
}
