terraform {
  backend "s3" {}
}

// API Gateway requires that ACM certificates reside in us-east-1.
provider "aws" {
  alias = "aws_acm_cert_region_for_edge"
  region = "us-east-1"
}

variable "environment" {
  description = "The environment this is running in."
}

variable "domain_path" {
  description = "The DNS path to affix to the domain_tld."
}

variable "domain_tld" {
  description = "The domain name to use; this is used for creating HTTPS certificates."
}

variable "app_account_name" {
  description = "The name of the app account to create for your app."
}

variable "no_certs" {
  description = "Flag to disable cert provisioning for development deployments."
  default = "false"
}

data "aws_route53_zone" "app_dns_zone" {
  name = "${var.domain_tld}."
}

data "aws_region" "current" {}

resource "random_string" "serverless_bucket_prefix" {
  length = 8
  upper = false
  special = false
}

resource "aws_s3_bucket" "serverless_bucket" {
  bucket = "${random_string.serverless_bucket_prefix.result}-${var.app_account_name}-serverless-bucket-${var.environment}"
}

resource "aws_iam_user" "app" {
  name = "${var.app_account_name}_account_${var.environment}"
}

resource "aws_iam_access_key" "app" {
  user = "${aws_iam_user.app.name}"
}

resource "aws_iam_user_policy" "app" {
  name = "${var.app_account_name}_account_policy_${var.environment}"
  user = "${aws_iam_user.app.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
     {
        "Action": ["s3:ListObjects"],
        "Effect": "Allow",
        "Resource": "*"
     }
  ]
}
EOF
}

resource "aws_acm_certificate" "app_cert" {
  count = "${var.no_certs == "true" ? 0 : 1 }"
  provider = aws.aws_acm_cert_region_for_edge
  domain_name = "${var.domain_path}.${var.domain_tld}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "app_cert_validation_cname" {
  provider = aws.aws_acm_cert_region_for_edge
  count   = "${var.no_certs == "true" ? 0 : 1 }"
  name    = "${tolist(aws_acm_certificate.app_cert.0.domain_validation_options).0.resource_record_name}"
  type    = "${tolist(aws_acm_certificate.app_cert.0.domain_validation_options).0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.app_dns_zone.id}"
  records = ["${tolist(aws_acm_certificate.app_cert.0.domain_validation_options).0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "app_cert" {
  provider = aws.aws_acm_cert_region_for_edge
  count = "${var.no_certs == "true" ? 0 : 1 }"
  certificate_arn         = "${aws_acm_certificate.app_cert.0.arn}"
  validation_record_fqdns = ["${aws_route53_record.app_cert_validation_cname.0.fqdn}"]
}

output "app_account_ak" {
  value = "${aws_iam_access_key.app.id}"
}

output "app_account_sk" {
  value = "${aws_iam_access_key.app.secret}"
}

output "certificate_arn" {
  value = "${var.no_certs == "true" ? "none" : aws_acm_certificate.app_cert.0.arn}"
}

output "bucket_name" {
  value = "${aws_s3_bucket.serverless_bucket.id}"
}
