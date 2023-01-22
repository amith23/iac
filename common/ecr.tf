provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "article_get_function" {
  name = "article_get_function"
}