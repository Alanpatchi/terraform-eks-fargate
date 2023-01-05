# TODO move to separate module for application development

resource "aws_eks_fargate_profile" "staging" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "staging"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile.arn

  # These subnets must have the following resource tag:
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = [
    aws_subnet.private-us-west-1b.id,
    aws_subnet.private-us-west-1c.id
  ]

  selector {
    namespace = "staging"
  }

  depends_on = [aws_iam_role_policy_attachment.eks-fargate-profile]

}
