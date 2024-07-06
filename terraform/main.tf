# Create Dynamoddb table
resource "aws_dynamodb_table" "resume_table" {
  name             = var.dynamodb_table_name
  hash_key         = "id"
  billing_mode     = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }
  
}

# Read data.json content and create DynamoDB item content
locals {
  data_content = file("../src/data.json")

}

# Add item/content to the DynamoDB table using item id from local block.
resource "aws_dynamodb_table_item" "resume_json" {
  table_name = aws_dynamodb_table.resume_table.name
  hash_key   = "id"

  item = local.data_content

  depends_on = [ aws_dynamodb_table.resume_table ]
}


# Create Lambda fucntion with python runtime
resource "aws_lambda_function" "test_lambda" {
  filename      = "../src/lambda_function.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "app.lambda_handler"

  source_code_hash = filebase64sha256("../src/lambda_function.zip")

  runtime = "python3.9"

}

# Create IAM role for lambda
resource "aws_iam_role" "iam_for_lambda" {
    name = "resume_lambda_role"

    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach lambda_policy policy to lambda role 
resource "aws_iam_role_policy_attachment" "lambda_policy" {
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    role = aws_iam_role.iam_for_lambda.name
  
}

# Create dynamodb read policy and attached to lambda role
resource "aws_iam_role_policy" "dynamodb_read_policy" {
  name = "dynamodb_read_policy"
  role = aws_iam_role.iam_for_lambda.id 

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:Scan",
      ]
      Resource = aws_dynamodb_table.resume_table.arn
    }]
  })
}

# Create api gateway of REST API type
resource "aws_api_gateway_rest_api" "resume_api" {
  name = "resume_api"

}

# Create resource of api gateway
resource "aws_api_gateway_resource" "resume_resource" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  parent_id   = aws_api_gateway_rest_api.resume_api.root_resource_id
  path_part   = "resume"

}

# Create api gateway method type GET
resource "aws_api_gateway_method" "resume_method" {
  rest_api_id   = aws_api_gateway_rest_api.resume_api.id
  resource_id   = aws_api_gateway_resource.resume_resource.id
  http_method   = "GET"
  authorization = "NONE"

}

# Integration of api gateway with lambda function
resource "aws_api_gateway_integration" "api_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  resource_id = aws_api_gateway_resource.resume_resource.id
  http_method = aws_api_gateway_method.resume_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.test_lambda.invoke_arn

}

# Explicitly allows API Gateway to call our Lambda function.
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.resume_api.execution_arn}/*/*"
}

# Create api gateway stage named prod and deploy
resource "aws_api_gateway_deployment" "resume_deployment" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  stage_name  = "prod"

  depends_on = [aws_api_gateway_integration.api_lambda_integration] #Make sure the api-gateway and lambda integration happens before prod stage deploy
}

# Create s3 bucket 
resource "aws_s3_bucket" "resume_bucket" {
  bucket = var.s3_bucket_name

}

# Allow public access to the bucket
resource "aws_s3_bucket_public_access_block" "resume_public_access" {
  bucket = aws_s3_bucket.resume_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

}

# Enable static webiste hosting
resource "aws_s3_bucket_website_configuration" "resume_website" {
  bucket = aws_s3_bucket.resume_bucket.id

  index_document {
    suffix = "index.html"
  }

}

# Create Bucket policy to allow everyone to index.html and restrict statefile access as well.
resource "aws_s3_bucket_policy" "resume_bucket_policy" {
  bucket = aws_s3_bucket.resume_bucket.id

  policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "allow public access to the bucket objects",
			"Principal": "*",
			"Effect": "Allow",
			"Action": [
				"s3:*"
			],
			"Resource": [
				"${aws_s3_bucket.resume_bucket.arn}",
        "${aws_s3_bucket.resume_bucket.arn}/*"
			]
		},
    {
        Sid       = "RestrictStateFileAccess",
        Effect    = "Deny",
        Principal = "*",
        Action    = "*",
        Resource  = "${aws_s3_bucket.resume_bucket.arn}/terraform.tfstate"
      }
    ]
  })

  depends_on = [ aws_s3_bucket_public_access_block.resume_public_access ]
}

resource "aws_s3_object" "index_html" {
    bucket = aws_s3_bucket.resume_bucket.id 
    key = "index.html"
    source = "../src/index.html"

    depends_on = [ aws_s3_bucket.resume_bucket,aws_s3_bucket_public_access_block.resume_public_access, aws_s3_bucket_policy.resume_bucket_policy  ]
}

