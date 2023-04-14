output "repository_id" {
  value = aws_codecommit_repository.repository.repository_id
}

output "repository_name" {
  value = aws_codecommit_repository.repository.repository_name
}

output "repository_arn" {
  value = aws_codecommit_repository.repository.arn
}

output "clone_url_http" {
    value = aws_codecommit_repository.repository.clone_url_http
}

output "clone_url_ssh" {
    value = aws_codecommit_repository.repository.clone_url_ssh
}
