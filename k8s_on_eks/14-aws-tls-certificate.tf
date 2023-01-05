#this resource is needed to be created for every single application that needs a sub-domain

# TODO this certificate request has to validated externally by making changes to RECORD set of alanpatchi.com
# as mentioned in the AWS Certificate Manager > Certificates, and then finally the certificate will be issued
resource "aws_acm_certificate" "cert" {
  domain_name       = "php-apache.alanpatchi.com"
  validation_method = "DNS"

  tags = {
    Application = "php-apache"
  }

  lifecycle {
    create_before_destroy = true
  }
}