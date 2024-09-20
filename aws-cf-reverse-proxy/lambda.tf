module "luthername_redirect_lambda_role" {
  count = var.use_302 ? 1 : 0

  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = "lambda"
  subcomponent   = "redirect"
  resource       = "role"
}

resource "aws_iam_role" "lambda_edge_role" {
  count = var.use_302 ? 1 : 0

  name = module.luthername_redirect_lambda_role[0].name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_edge_policy" {
  count = var.use_302 ? 1 : 0

  role       = aws_iam_role.lambda_edge_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

module "luthername_redirect_lambda" {
  count = var.use_302 ? 1 : 0

  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = "cf"
  subcomponent   = "redirect"
  resource       = "lambda"
}

resource "aws_lambda_function" "edge_function" {
  count = var.use_302 ? 1 : 0

  function_name = module.luthername_redirect_lambda[0].name
  role          = aws_iam_role.lambda_edge_role[0].arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  publish       = true
  filename      = data.archive_file.lambda_edge_zip.output_path

  environment {
    variables = {
      REDIRECT_URL       = var.origin_url
      REDIRECT_HTTP_CODE = 302
    }
  }

  tags = module.luthername_redirect_lambda[0].tags
}

data "archive_file" "lambda_edge_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda.zip"
}
