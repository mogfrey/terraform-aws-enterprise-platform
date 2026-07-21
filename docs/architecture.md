# Architecture decisions

## Context

The reference platform represents a regulated enterprise workload that requires private control-plane access, auditable network flows, explicit ownership and a path to centrally managed connectivity. It is intentionally smaller than a complete landing zone: organizational units, account vending, identity federation, centralized inspection and backup are upstream capabilities.

## Network segmentation

| Tier | Purpose | Default internet route |
|---|---|---|
| Platform | EKS nodes and internal load balancers | Disabled unless NAT is explicitly enabled |
| Data | Databases, caches and stateful services | None |
| Endpoints | Interface endpoints for AWS APIs | None |
| Public egress | Optional NAT gateway only | Internet gateway |

The subnets are separated even where network ACLs remain at their defaults. The separation creates clear routing and security boundaries and allows each tier to evolve independently.

## Private service access

The example creates endpoints for ECR, S3, STS, CloudWatch Logs and Systems Manager. These cover common EKS bootstrap and operational paths. A real implementation should build its endpoint list from observed dependencies rather than adding every available service.

Endpoint policies should then restrict access to approved principals and resources. They are not included here because useful policies depend on the organization’s account structure and artifact repositories.

## EKS control plane

The API endpoint is private. This avoids treating CIDR allow lists on a public endpoint as the primary boundary. Administrators need routed private connectivity and an authorized EKS access entry or federated role.

Control-plane logs are enabled for API activity, audit events, authentication, controllers and scheduling. Kubernetes secrets use envelope encryption with a customer-managed KMS key.

## Node egress

The security group allows outbound traffic, but reachability is still determined by routes. With NAT disabled, nodes use VPC endpoints and private routed destinations only. Kubernetes network policy should provide workload-level egress control; security groups alone cannot express pod-level intent in every networking model.

## NAT trade-off

A single NAT gateway is a useful development option but is not a highly available production egress design. Production choices include:

1. one NAT gateway per availability zone;
2. centralized egress through a transit and inspection VPC;
3. endpoint-only workloads with tightly controlled proxies;
4. a mixture selected per workload tier.

The correct choice depends on recovery objectives, inspection requirements, data-transfer cost and operational ownership.

## State and delivery

Remote Terraform state, locking, CI identity and policy checks are intentionally external to this root module. A production delivery pipeline should include:

- encrypted remote state with restricted read access;
- short-lived workload identity instead of static keys;
- `terraform fmt`, `validate`, linting and security scanning;
- reviewed plans and protected deployment environments;
- drift detection and an auditable exception process.
