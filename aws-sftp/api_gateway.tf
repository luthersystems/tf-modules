module "luthername_transfer_server_api" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "sftp"
  resource       = "api"

  providers = {
    template = template
  }
}

resource "aws_api_gateway_rest_api" "transfer_auth" {
  name = module.luthername_transfer_server_api.names[0]

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# /servers/serverId/users/username/config
resource "aws_api_gateway_resource" "transfer_auth_servers" {
  rest_api_id = aws_api_gateway_rest_api.transfer_auth.id
  parent_id   = aws_api_gateway_rest_api.transfer_auth.root_resource_id
  path_part   = "servers"
}

resource "aws_api_gateway_resource" "transfer_auth_server_id" {
  rest_api_id = aws_api_gateway_rest_api.transfer_auth.id
  parent_id   = aws_api_gateway_resource.transfer_auth_servers.id
  path_part   = "{serverId}"
}

resource "aws_api_gateway_resource" "transfer_auth_users" {
  rest_api_id = aws_api_gateway_rest_api.transfer_auth.id
  parent_id   = aws_api_gateway_resource.transfer_auth_server_id.id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "transfer_auth_username" {
  rest_api_id = aws_api_gateway_rest_api.transfer_auth.id
  parent_id   = aws_api_gateway_resource.transfer_auth_users.id
  path_part   = "{username}"
}

resource "aws_api_gateway_resource" "transfer_auth_user_config" {
  rest_api_id = aws_api_gateway_rest_api.transfer_auth.id
  parent_id   = aws_api_gateway_resource.transfer_auth_username.id
  path_part   = "config"
}

resource "aws_api_gateway_method" "transfer_auth_get_config" {
  rest_api_id   = aws_api_gateway_rest_api.transfer_auth.id
  resource_id   = aws_api_gateway_resource.transfer_auth_user_config.id
  http_method   = "GET"
  authorization = "AWS_IAM"

  request_parameters = {
    "method.request.header.Password" = false
  }
}

resource "aws_api_gateway_model" "transfer_auth_response_model" {
  rest_api_id  = aws_api_gateway_rest_api.transfer_auth.id
  name         = "UserConfigResponseModel"
  description  = "API response for GET user config"
  content_type = "application/json"
  schema       = file("${path.module}/files/response_schema.json")
}

resource "aws_api_gateway_method_response" "transfer_auth_get_config_200" {
  rest_api_id = aws_api_gateway_rest_api.transfer_auth.id
  resource_id = aws_api_gateway_resource.transfer_auth_user_config.id
  http_method = aws_api_gateway_method.transfer_auth_get_config.http_method
  status_code = "200"

  response_models = {
    "application/json" = "UserConfigResponseModel"
  }

  depends_on = [aws_api_gateway_model.transfer_auth_response_model]
}

resource "aws_api_gateway_integration" "transfer_auth_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.transfer_auth.id
  resource_id             = aws_api_gateway_resource.transfer_auth_user_config.id
  http_method             = aws_api_gateway_method.transfer_auth_get_config.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.transfer_auth.invoke_arn

  request_templates = {
    "application/json" = file("${path.module}/files/request_template.json")
  }
}

resource "aws_api_gateway_integration_response" "transfer_auth_lambda_response" {
  rest_api_id = aws_api_gateway_rest_api.transfer_auth.id
  resource_id = aws_api_gateway_resource.transfer_auth_user_config.id
  http_method = aws_api_gateway_method.transfer_auth_get_config.http_method
  status_code = aws_api_gateway_method_response.transfer_auth_get_config_200.status_code

  depends_on = [aws_api_gateway_integration.transfer_auth_lambda]
}

resource "aws_api_gateway_deployment" "transfer_auth" {
  depends_on  = [aws_api_gateway_integration.transfer_auth_lambda]
  rest_api_id = aws_api_gateway_rest_api.transfer_auth.id

  lifecycle {
    create_before_destroy = true
  }
  # TODO - update on dependency change
}

resource "aws_api_gateway_stage" "transfer_auth" {
  stage_name    = "v1"
  rest_api_id   = aws_api_gateway_rest_api.transfer_auth.id
  deployment_id = aws_api_gateway_deployment.transfer_auth.id

  access_log_settings {
    destination_arn = var.cloudwatch_log_group
    format          = chomp(file("${path.module}/files/api-log-format"))
  }
}

resource "aws_lambda_permission" "transfer_auth_api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transfer_auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_stage.transfer_auth.execution_arn}/GET${aws_api_gateway_resource.transfer_auth_user_config.path}"
}
