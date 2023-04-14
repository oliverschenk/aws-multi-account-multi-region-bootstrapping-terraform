output "codebuild_project_id" {
  value = aws_codebuild_project.codebuild.id
}

output "codebuild_project_name" {
  value = aws_codebuild_project.codebuild.name
}

output "codebuild_role_arn" {
  value = aws_iam_role.codebuild.arn
}

output "codebuild_role_name" {
  value = aws_iam_role.codebuild.name
}