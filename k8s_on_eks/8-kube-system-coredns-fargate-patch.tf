provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

data "aws_eks_cluster" "main" {
  name = aws_eks_cluster.cluster.name
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.cluster.name
}

resource "kubernetes_service_account" "core_dns_fixer" {
  metadata {
    name      = "core-dns-fixer"
    namespace = "kube-system"
  }
}

resource "kubernetes_role" "core_dns_fixer" {
  metadata {
    name = "core-dns-fixer"
    namespace = "kube-system"
  }

  rule {
    api_groups     = ["apps"]
    resources      = ["deployments"]
    resource_names = ["coredns"]
    verbs          = ["get", "patch"]
  }
}

resource "kubernetes_role_binding" "core_dns_fixer" {
  metadata {
    name      = "core-dns-fixer"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.core_dns_fixer.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.core_dns_fixer.metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_job" "patch_core_dns" {
  depends_on = [
    # assumes the `kube-system` fargate profile is created in the same code
    # edit to match yours, or comment out if it's being created elsewhere
    aws_eks_fargate_profile.kube-system,
    kubernetes_role_binding.core_dns_fixer
  ]
  metadata {
    name      = "patch-core-dns"
    namespace = "kube-system"
  }
  spec {
    template {
      metadata {}
      spec {
        service_account_name = kubernetes_service_account.core_dns_fixer.metadata[0].name
        container {
          name    = "patch-core-dns"
          image   = "bitnami/kubectl:latest"
          command = ["/bin/sh", "-c", "kubectl patch deployments.app/coredns -n kube-system --type json -p='[{\"op\": \"remove\", \"path\": \"/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type\"}]'"]
        }
        restart_policy = "Never"
      }
    }
  }
  wait_for_completion = true
  timeouts {
    create = "5m"
  }
}

resource "kubernetes_job" "restart_core_dns" {
  depends_on = [
    kubernetes_job.patch_core_dns
  ]
  metadata {
    name      = "restart-core-dns"
    namespace = "kube-system"
  }
  spec {
    template {
      metadata {}
      spec {
        service_account_name = kubernetes_service_account.core_dns_fixer.metadata[0].name
        container {
          name    = "restart-core-dns"
          image   = "bitnami/kubectl:latest"
          command = ["/bin/sh", "-c", "kubectl rollout restart deployments.app/coredns -n kube-system"]
        }
        restart_policy = "Never"
      }
    }
  }
  wait_for_completion = true
  timeouts {
    create = "5m"
  }
}