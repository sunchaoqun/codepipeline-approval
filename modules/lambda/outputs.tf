output "arn" {
  value       = aws_lambda_function.terraform_lambda_func.arn
  description = "The ARN of the Lambda Checker ARN"
}