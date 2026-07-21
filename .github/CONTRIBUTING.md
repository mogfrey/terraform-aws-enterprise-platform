# Contributing

This repository is a public, sanitized reference architecture. Contributions must remain reusable and must not reproduce any employer, customer or production environment.

## Safety requirements

- Use synthetic CIDRs, placeholder account IDs and documentation-only domains.
- Never commit credentials, Terraform state, plans, certificates, internal endpoints or cloud exports.
- Preserve private-by-default networking and least-privilege identity unless a documented design decision requires otherwise.
- Explain reliability, security and cost trade-offs for architecture changes.

## Validation

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
terraform plan -var-file=examples/dev.tfvars
```

A plan requires an authenticated lab account and must be reviewed before any apply. Do not deploy this root module unchanged into a production account.
