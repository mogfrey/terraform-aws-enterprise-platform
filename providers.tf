terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project        = var.project_name
      Environment    = var.environment
      Resource_Owner = var.resource_owner
      Department     = var.department
      Managed_By     = "Terraform"
      Repository     = "terraform-aws-enterprise-platform"
    },
    var.additional_tags
  )
}
