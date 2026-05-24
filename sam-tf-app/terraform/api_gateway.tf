# API 本体
resource "aws_api_gateway_rest_api" "hello" {
  name = "hello-api"
}

# /hello パス
resource "aws_api_gateway_resource" "hello" {
  rest_api_id = aws_api_gateway_rest_api.hello.id
  parent_id   = aws_api_gateway_rest_api.hello.root_resource_id
  path_part   = "hello"
}

# GET メソッド
resource "aws_api_gateway_method" "hello" {
  rest_api_id   = aws_api_gateway_rest_api.hello.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "GET"
  authorization = "NONE"
}

# Lambda との接続
resource "aws_api_gateway_integration" "hello" {
  rest_api_id             = aws_api_gateway_rest_api.hello.id
  resource_id             = aws_api_gateway_resource.hello.id
  http_method             = aws_api_gateway_method.hello.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello.invoke_arn
}

# デプロイ
resource "aws_api_gateway_deployment" "hello" {
  rest_api_id = aws_api_gateway_rest_api.hello.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.hello.id,
      aws_api_gateway_method.hello.id,
      aws_api_gateway_integration.hello.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_integration.hello]
}

# ステージ
resource "aws_api_gateway_stage" "stg" {
  rest_api_id   = aws_api_gateway_rest_api.hello.id
  deployment_id = aws_api_gateway_deployment.hello.id
  stage_name    = "stg"
}

# API Gateway が Lambda を呼ぶ権限
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.hello.execution_arn}/*/*"
}

# エンドポイント URL を出力
output "api_endpoint" {
  value = "${aws_api_gateway_stage.stg.invoke_url}/hello"
}
