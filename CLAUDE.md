# CLAUDE.md

`terraform-aws-ecr` — a reusable Harri Terraform **module**, published to the HCP
private registry.

## What This Module Provisions

- `aws_ecr_repository` (private) or `aws_ecrpublic_repository` (public), chosen
  by `repository_type`; nothing is created unless `create` and
  `create_repository` are both on.
- A repository policy — generated from `repository_read_access_arns`,
  `repository_read_write_access_arns` and `repository_lambda_read_access_arns`
  when `create_repository_policy`, otherwise the caller's `repository_policy` —
  attached when `attach_repository_policy` (private repositories).
- `aws_ecr_lifecycle_policy` from `repository_lifecycle_policy` when
  `create_lifecycle_policy` (private repositories).
- Registry-level settings, each off until enabled: registry policy, pull-through
  cache rules, registry scanning configuration, and replication configuration.
- `wrappers/` calls the module once per entry of `items`, filling unset fields
  from `defaults` — this is how the `Terraform*Stack` repos consume it.

## Registry Source

How the stacks call it — through the wrapper, one `items` entry per repository:

```hcl
component "ecr-repositories" {
  source  = "app.terraform.io/harri/ecr-module/aws//wrappers"
  version = "x.y.z"   # pin the current published version
  inputs = {
    items    = var.ecr_repositories   # one entry per repository
    defaults = {                      # shared by every entry unless it overrides
      repository_policy           = component.policies.ecr_policy_document
      repository_lifecycle_policy = component.policies.ecr_lifecycle_policy_document
    }
  }
}
```

A single repository can call the root directly
(`source = "app.terraform.io/harri/ecr-module/aws"`); it has no required inputs.

> Take the current published version from the HCP private registry, or from the
> `version` pinned beside this `source` in a consumer's `common/resources.tf`.
> Consumers pin an exact version; ranges are never allowed.

## Required Versions

Read them from **`versions.tf`**: `required_version` for Terraform core, and each
`required_providers` entry for the providers. They are not repeated here, so this
guide cannot go stale when they change.

## File Layout

```
terraform-aws-ecr/
├── CHANGELOG.md                   # release notes
├── LICENSE                        # upstream licence
├── README.md                      # usage example, inputs/outputs reference
├── main.tf                        # the resources this module creates
├── outputs.tf                     # what consumers can wire
├── variables.tf                   # inputs
├── versions.tf                    # Terraform + provider constraints
├── examples/complete/             # standalone example callers
├── examples/repository-template/  # standalone example callers
├── modules/repository-template/   # nested submodules
└── wrappers/                      # for_each wrapper for calling the module many times
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `create` | `bool` | `true` | Determines whether resources will be created (affects all resources) |
| `tags` | `map(string)` | `{}` | A map of tags to add to all resources |
| `repository_type` | `string` | `"private"` | The type of repository to create. Either `public` or `private` |
| `region` | `string` | `null` | Region where this resource will be managed. Defaults to the Region set in the provider configuration. |
| `create_repository` | `bool` | `true` | Determines whether a repository will be created |
| `repository_name` | `string` | `""` | The name of the repository |
| `repository_image_tag_mutability` | `string` | `"IMMUTABLE"` | The tag mutability setting for the repository. Must be one of: `MUTABLE`, `MUTABLE_WITH_EXCLUSION`, `IMMUTABLE`, or `IMMUTABLE_WITH_EXCLUSION`. Defaults to `IMMUTABLE` |
| `repository_encryption_type` | `string` | `null` | The encryption type for the repository. Must be one of: `KMS` or `AES256`. Defaults to `AES256` |
| `repository_kms_key` | `string` | `null` | The ARN of the KMS key to use when encryption_type is `KMS`. If not specified, uses the default AWS managed key for ECR |
| `repository_image_scan_on_push` | `bool` | `true` | Indicates whether images are scanned after being pushed to the repository (`true`) or not scanned (`false`) |
| `repository_policy` | `string` | `null` | The JSON policy to apply to the repository. If not specified, uses the default policy |
| `repository_force_delete` | `bool` | `null` | If `true`, will delete the repository even if it contains images. Defaults to `false` |
| `repository_image_tag_mutability_exclusion_filter` | `list(object({…}))` | `null` | Configuration block that defines filters to specify which image tags can override the default tag mutability setting. Only applicable when image_tag_mutability is set to IMMUTABLE_WITH_EXCLUSION or MUTABLE_WITH_EXCLUSION. |
| `attach_repository_policy` | `bool` | `true` | Determines whether a repository policy will be attached to the repository |
| `create_repository_policy` | `bool` | `true` | Determines whether a repository policy will be created |
| `repository_read_access_arns` | `list(string)` | `[]` | The ARNs of the IAM users/roles that have read access to the repository |
| `repository_lambda_read_access_arns` | `list(string)` | `[]` | The ARNs of the Lambda service roles that have read access to the repository |
| `repository_read_write_access_arns` | `list(string)` | `[]` | The ARNs of the IAM users/roles that have read/write access to the repository |
| `repository_policy_statements` | `map(object({…}))` | `null` | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage |
| `create_lifecycle_policy` | `bool` | `true` | Determines whether a lifecycle policy will be created |
| `repository_lifecycle_policy` | `string` | `""` | The policy document. This is a JSON formatted string. See more details about [Policy Parameters](http://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html#lifecycle_policy_parameters) in the official AWS docs |
| `public_repository_catalog_data` | `object({…})` | `null` | Catalog data configuration for the repository |
| `create_registry_policy` | `bool` | `false` | Determines whether a registry policy will be created |
| `registry_policy` | `string` | `null` | The policy document. This is a JSON formatted string |
| `registry_pull_through_cache_rules` | `map(object({…}))` | `{}` | List of pull through cache rules to create |
| `manage_registry_scanning_configuration` | `bool` | `false` | Determines whether the registry scanning configuration will be managed |
| `registry_scan_type` | `string` | `"ENHANCED"` | the scanning type to set for the registry. Can be either `ENHANCED` or `BASIC` |
| `registry_scan_rules` | `list(object({…}))` | `null` | One or multiple blocks specifying scanning rules to determine which repository filters are used and at what frequency scanning will occur |
| `create_registry_replication_configuration` | `bool` | `false` | Determines whether a registry replication configuration will be created |
| `registry_replication_rules` | `list(object({…}))` | `null` | The replication rules for a replication configuration. A maximum of 10 are allowed |

## Outputs

| Name | Description |
|---|---|
| `repository_name` | Name of the repository |
| `repository_arn` | Full ARN of the repository |
| `repository_registry_id` | The registry ID where the repository was created |
| `repository_url` | The URL of the repository |

## Submodules

| Submodule | Role |
|---|---|
| `repository-template` | ECR repository creation templates (`aws_ecr_repository_creation_template`), with an optional pull-through cache rule and the IAM role and policy they use; also wrapped by `wrappers/repository-template/` |

## Examples

- `examples/complete` — private and public repositories plus the registry-level settings
- `examples/repository-template` — repository creation templates, including pull-through cache

## Conventions & Naming

### Project naming patterns

- The repository is named exactly `repository_name`.
- Stacks consume the wrapper, not the root:
  `app.terraform.io/harri/ecr-module/aws//wrappers`, with one `items` entry per
  repository. A field left out of an entry falls back to `defaults`, then to the
  wrapper's own default.
- Registry-level resources act on the whole account's registry, not one
  repository — enable them in one place only, or two callers will fight over them.
- The repo is a fork of the public `terraform-aws-modules/terraform-aws-ecr`
  (`upstream` remote); `CHANGELOG.md` and `LICENSE` come from upstream.
