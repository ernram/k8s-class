data "aws_availability_zones" "available" {}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}
