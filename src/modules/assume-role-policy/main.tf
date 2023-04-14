###############################################################################
# A policy document that grants role assumption to a given role name in a given
# account.
###############################################################################
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid = "Assume${replace(title(var.account_name), "/-| /", "")}${replace(title(var.role_name), "/-| /", "")}Role"
    actions = [
      "sts:AssumeRole"
    ]

    resources = [
      "arn:aws:iam::${var.account_id}:role/${var.role_name}",
    ]
  }
}

###############################################################################
# A policy that grants role assumption to a given role name in a given account
# using the assume_role policy document defined above
###############################################################################
resource "aws_iam_policy" "assume_role" {
  name        = "${replace(title(var.account_name), "/-| /", "")}${replace(title(var.role_name), "/-| /", "")}RoleAccess"
  policy      = data.aws_iam_policy_document.assume_role.json
  description = "Grants role assumption for the ${title(var.role_name)} role in the ${title(var.account_name)} account"

  tags = module.this.tags
}
