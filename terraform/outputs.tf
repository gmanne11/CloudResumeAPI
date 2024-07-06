output "aws_s3_endpoint_url" {
    value = aws_s3_bucket_website_configuration.resume_website.website_endpoint
  
}

output "aws_dynamodb_table_name" {
    value = aws_dynamodb_table.resume_table.name
  
}

output "lambda_fucntion_name" {
    value = aws_lambda_function.test_lambda.function_name
  
}

output "aws_lambda_iam_role_name" {
    value = aws_iam_role.iam_for_lambda.name
  
}

output "dynamo_db_policy_name" {
    value = aws_iam_role_policy.dynamodb_read_policy.name
  
}

output "api_gateway_name" {
    value = aws_api_gateway_rest_api.resume_api.arn
  
}

output "s3_bucket_name" {
    value = aws_s3_bucket.resume_bucket.arn
  
}

output "api_gateway_endpoint_url" {
    value = aws_api_gateway_deployment.resume_deployment.invoke_url
  
}

output "aws_api_gateway_lambda_execution_arn" {
    value = aws_api_gateway_rest_api.resume_api.execution_arn
}



