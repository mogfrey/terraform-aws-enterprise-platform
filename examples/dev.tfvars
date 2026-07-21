aws_region         = "eu-west-1"
availability_zones = ["eu-west-1a", "eu-west-1b"]

project_name   = "cloud-platform"
environment    = "dev"
resource_owner = "platform-engineering@example.com"
department     = "Engineering"

vpc_cidr          = "10.42.0.0/16"
enable_nat_gateway = false

# Pin this to an approved EKS version in a real deployment.
kubernetes_version = null

node_instance_types = ["m6i.large"]
node_ami_type       = "AL2023_x86_64_STANDARD"
node_min_size       = 2
node_desired_size   = 2
node_max_size       = 4

additional_tags = {
  Cost_Centre         = "CC-DEMO-001"
  Data_Classification = "Internal"
  Business_Service    = "Cloud Platform Lab"
}
