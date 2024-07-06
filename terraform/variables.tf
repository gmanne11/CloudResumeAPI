variable "dynamodb_table_name" {
    default = "ResumeTable"
}

variable "lambda_function_name" {
    default = "my-lambda"
}

variable "s3_bucket_name" {
    default = "vivekresumebucket"
  
}

variable "aws_region" {
    default = "us-east-1"
  
}
