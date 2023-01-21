provider "aws" {
  region = "us-east-1"
}
##-----------------------------###
## API GATEWAY FOR SERVICE     ###
##-----------------------------###

resource "aws_api_gateway_rest_api" "api_gateway_rest_api" {
  name = "api_gateway_rest_api"
}

resource "aws_api_gateway_resource" "api_gateway_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway_rest_api.id
  parent_id   = aws_api_gateway_rest_api.api_gateway_rest_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "gateway_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway_rest_api.id
  resource_id   = aws_api_gateway_resource.api_gateway_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowAPI Gateway"
  action        = "lambda:InvokeFunction"
  function_name = "article_service_blue"
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_api_gateway_method.gateway_method.execution_arn
}

resource "aws_api_gateway_integration" "api_gateway_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway_rest_api.id
  resource_id             = aws_api_gateway_resource.api_gateway_resource.id
  http_method             = aws_api_gateway_method.gateway_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:477827136140:function:article_service_blue/invocations"
}


##-----------------------------###
resource "aws_lambda_function" "article_service_blue" {
  function_name = "article_service_blue"
  runtime = "provided"
  package_type = "Image"
  image_uri = "477827136140.dkr.ecr.us-east-1.amazonaws.com/article_service:latest"
  role = aws_iam_role.lambda_role.arn
}

#resource "aws_lambda_function" "article_service_green" {
#  function_name = "article_service_green"
#  runtime = "provided"
#  package_type = "Image"
#  image_uri = "477827136140.dkr.ecr.us-east-1.amazonaws.com/article_service:latest"
#  role = aws_iam_role.lambda_role.arn
#}

resource "aws_lambda_alias" "alias_article_service_blue" {
  name = "alias_article_service_blue"
  function_name = aws_lambda_function.article_service_blue.function_name
  function_version = aws_lambda_function.article_service_blue.version
}

#resource "aws_lambda_alias" "alias_article_service_green" {
#  name = "alias_article_service_green"
#  function_name = aws_lambda_function.article_service_green.function_name
#  function_version = aws_lambda_function.article_service_green.version
#}


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
      "Action": "*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:BatchCheckLayerAvailability",
      "Resource": "arn:aws:ecr:us-west-2:01234567890:repository/my-lambda-image"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetDownloadUrlForLayer",
      "Resource": "arn:aws:ecr:us-west-2:01234567890:repository/my-lambda-image"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:BatchGetImage",
      "Resource": "arn:aws:ecr:us-west-2:01234567890:repository/my-lambda-image"
    }
  ]
}
EOF
}