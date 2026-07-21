variable "aws_region" {
  description = "AWS region in which to deploy the platform."
  type        = string
  default     = "eu-west-1"
}

variable "availability_zones" {
  description = "At least two availability zones used by the platform."
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2 && length(distinct(var.availability_zones)) == length(var.availability_zones)
    error_message = "Provide at least two unique availability zones."
  }
}

variable "project_name" {
  description = "Short project or platform name used in resource names and tags."
  type        = string
  default     = "enterprise-platform"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "uat", "prod"], var.environment)
    error_message = "Environment must be dev, test, uat or prod."
  }
}

variable "resource_owner" {
  description = "Accountable owner recorded on all taggable resources."
  type        = string
}

variable "department" {
  description = "Owning department or cost-allocation unit."
  type        = string
}

variable "vpc_cidr" {
  description = "Synthetic or approved CIDR assigned to the platform VPC."
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "enable_nat_gateway" {
  description = "Create a single lab NAT gateway for workloads that need internet egress. Production designs should explicitly assess per-AZ or centralized egress."
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Approved EKS Kubernetes version. Null allows AWS to select the current default."
  type        = string
  default     = null
  nullable    = true
}

variable "node_instance_types" {
  description = "EC2 instance types used by the managed node group."
  type        = list(string)
  default     = ["m6i.large"]
}

variable "node_ami_type" {
  description = "AMI family for the EKS managed node group."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_min_size" {
  description = "Minimum managed node group size."
  type        = number
  default     = 2
}

variable "node_desired_size" {
  description = "Desired managed node group size."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum managed node group size."
  type        = number
  default     = 4
}

variable "additional_tags" {
  description = "Additional organization-specific tags."
  type        = map(string)
  default     = {}
}
