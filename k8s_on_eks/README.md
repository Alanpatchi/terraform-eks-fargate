Configures infrastructure that
- sets-up on an eks cluster with fargate profiles

# AWS CONFIG:
1. Install aws cli
2. Set up aws config and credentials

# INIT: 

The following has to be done manually, as of now, for k8s/5-ingress.yaml to handle AWS issued TLS certificates within k8s's ingress :
1. Perform terraform init -> terraform apply
2. Do the changes as mentioned in "14-aws-tls-certificate.tf", and once the certificate is issued 
3. Perform [Kubectl config](#kubectl-config)
4. Perform "kubectl apply -f k8s/"
5. Do the changes as mentioned in "5-ingress.yaml", to access the application externally.

# KUBECTL CONFIG:
1. Install kubectl cli
2. Set kubectl to point to aws eks

# DESTROY:

1. Delete the aws load balancer deployed by k8s ingress by "https://stackoverflow.com/a/70860318/6270888"
   1. Or, better all the k8s resources, in the namespace used by application which includes ingress by deleting the namespace itself, by "https://stackoverflow.com/a/69944777/6270888"
   2. Eg: "kubectl delete ns staging"
2. Perform "terraform destroy"
3. Undo the manual changes done as mentioned in "14-aws-tls-certificate.tf"
