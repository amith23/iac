provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "article_service_blue" {
  function_name = "article_service_blue"
  runtime = "provided"
  package_type = "Image"
  image_uri = "477827136140.dkr.ecr.us-east-1.amazonaws.com/article_service:latest"
  role = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_alias" "alias_article_service_blue" {
  name = "alias_article_service_blue"
  function_name = aws_lambda_function.article_service_blue.function_name
  function_version = aws_lambda_function.article_service_blue.version
}


resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": ["sts:AssumeRole"]
    }
    ]
}
EOF
}

resource "aws_iam_role_policy" "article_service_iam_policy" {
  name = "article_service_iam_policy"
  role = aws_iam_role.lambda_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "logs:*",
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:BatchCheckLayerAvailability",
      "Resource": "arn:aws:ecr:us-east-1:477827136140:repository/article_service"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetDownloadUrlForLayer",
      "Resource": "arn:aws:ecr:us-east-1:477827136140:repository/article_service"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:BatchGetImage",
      "Resource": "arn:aws:ecr:us-east-1:477827136140:repository/article_service"
    }
  ]
}
EOF
}

## API GATEWAY FOR THE FUNCTION 

resource "aws_api_gateway_rest_api" "as_rest_api" {
  name = "as_rest_api"
}

resource "aws_api_gateway_resource" "as_gateway_resource" {
  rest_api_id = aws_api_gateway_rest_api.as_rest_api.id
  parent_id = aws_api_gateway_rest_api.as_rest_api.root_resource_id
  path_part = "as_gateway_resource"
}

resource "aws_api_gateway_integration" "as_gateway_integration" {
  rest_api_id = aws_api_gateway_rest_api.as_rest_api.id
  resource_id = aws_api_gateway_resource.as_gateway_resource.id
  http_method = "OPTIONS"
  type = "AWS_PROXY"
  uri = aws_lambda_function.article_service_blue.invoke_arn
}

## we will add authorization later
resource "aws_api_gateway_method" "as_gateway_method" {
  rest_api_id = aws_api_gateway_rest_api.as_rest_api.id
  resource_id = aws_api_gateway_resource.as_gateway_resource.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_deployment" "as_gateway_deployment" {
  depends_on = [aws_lambda_function.article_service_blue]
  rest_api_id = aws_api_gateway_rest_api.as_rest_api.id
  stage_name = "prod"
}