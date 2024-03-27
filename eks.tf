locals {
  name = "my-eks-cluster"
  tags = {
    Name = local.name
  }
}
################################################################################
# EKS Module
################################################################################

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name                   = local.name
  cluster_version                = "1.27"
  cluster_endpoint_public_access = true

  # IPV6
  cluster_ip_family = "ipv4"

  # We are using the IRSA created below for permissions
  # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
  # and then turn this off after the cluster/node group is created. Without this initial policy,
  # the VPC CNI fails to assign IPs and nodes cannot join the cluster
  # See https://github.com/aws/containers-roadmap/issues/1666 for more context
  # TODO - remove this policy once AWS releases a managed version similar to AmazonEKS_CNI_Policy (IPv4)
  create_cni_ipv6_iam_policy = false

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent              = true
      before_compute           = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  manage_aws_auth_configmap = true

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3.medium"]

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {
    # Default node group - as provided by AWS EKS
    # default_node_group = {
    #   # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
    #   # so we need to disable it to use the default template provided by the AWS EKS managed node group service
    #   use_custom_launch_template = false

    #   disk_size = 50

    #   # Remote access cannot be specified with a launch template
    #   remote_access = {
    #     ec2_ssh_key               = aws_key_pair.ec2_key.key_name
    #     # source_security_group_ids = [aws_security_group.remote_access.id] 
    #   }
    # }

    # Complete
    complete = {
      name            = "complete-eks-mng"
      use_name_prefix = true

      subnet_ids = module.vpc.private_subnets

      min_size     = 1
      max_size     = 3
      desired_size = 3

      capacity_type        = "SPOT"
      force_update_version = true
      instance_types       = ["t3.medium"]
      labels = {
        GithubRepo = "terraform-aws-eks"
        GithubOrg  = "terraform-aws-modules"
      }

      description = "EKS managed node group example launch template"

      ebs_optimized           = true
      disable_api_termination = false
      enable_monitoring       = false

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            delete_on_termination = true
          }
        }
      }


      create_iam_role          = true
      iam_role_name            = "eks-managed-node-group-complete-example"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS managed node group complete example role"
      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }

      tags = {
        ExtraTag = "EKS managed node group complete example"
      }
    }
  }
}
