data "aws_subnets" "available-subnets"{
    filter {
    
      name = "tag:Name"
      values = ["our-public-*"]
      
    }

    filter {
      name = "availabilityZone"
      values = ["ap-south-1a", "ap-south-1b"]


    }

}

resource "aws_eks_cluster" "ankit-cluster" {
  name     = "ankit-cluster"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = ["subnet-0f80eb97f3a2b1346" , "subnet-0aa64babb6b5d1633"]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.example-AmazonEKSVPCResourceController,
  ]
}

output "endpoint" {
  value = aws_eks_cluster.ankit-cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.ankit-cluster.certificate_authority[0].data
}

resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.ankit-cluster.name
  node_group_name = "pc-node-group"
  node_role_arn   = aws_iam_role.worker.arn
  subnet_ids      = data.aws_subnets.available-subnets.ids
  capacity_type   = "ON_DEMAND"
  disk_size       = "20"
  instance_types  = ["t2.micro"]
  labels = tomap({ env = "dev" })

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
    ]  
}
