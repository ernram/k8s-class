resource "aws_key_pair" "ec2_key" {
  key_name   = "eks-key"
  public_key = "MAKING A CHANGE TO DEMONSTRATE GIT"
}
