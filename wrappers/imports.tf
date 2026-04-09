import {
  for_each = {for k,v in var.items : k => v if v.enable_import}
  to       = module.wrapper[each.key].aws_ecr_repository.this[0]
  id       = each.key
}

import {
  for_each = {for k,v in var.items : k => v if v.enable_import}
  to       = module.wrapper[each.key].aws_ecr_repository_policy.this[0]
  id       = each.key
}

import {
  for_each = {for k,v in var.items : k => v if v.enable_import}
  to       = module.wrapper[each.key].aws_ecr_lifecycle_policy.this[0]
  id       = each.key
}
