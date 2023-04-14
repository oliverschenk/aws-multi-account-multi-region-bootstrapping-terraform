###############################################################################
# Create a role with an assume role policy. The assume role policy is used to
# grant permission for another account or service to assume this role.
###############################################################################
resource "aws_iam_role" "role" {
  name               = replace(title(var.role_name), "/-| /", "")
  assume_role_policy = var.assume_role_policy_json

  tags = module.this.tags
}

###############################################################################
# Attach a role policy to the role defined above. The role policy is used to
# grant the role permission to perform actions. 
###############################################################################
resource "aws_iam_role_policy_attachment" "role_policy" {
  role       = aws_iam_role.role.name
  policy_arn = var.role_policy_arn
}
