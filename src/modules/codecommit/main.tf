resource "aws_codecommit_repository" "repository" {
  repository_name = "${module.this.namespace}-${module.this.name}-${var.aws_region}-${var.repository_name}"
  description     = var.repository_description

  tags = module.this.tags
}
