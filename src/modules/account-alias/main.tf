resource "aws_iam_account_alias" "alias" {
  account_alias = "${module.this.namespace}-${module.this.name}-${var.account_alias}"
}
