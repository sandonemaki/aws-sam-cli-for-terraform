# sam build --hook-name terraform --terraform-project-root-path  ./terraform/.terraform/providers/
locals {
  # 絶対パスでプロジェクトルートを定義
  project_root    = abspath("${path.module}/..")
  lambda_src_path = "${local.project_root}/functions/hello"
  build_output    = "${local.project_root}/.build"
}

# ① Go のビルド（GOOS=linux が必須）
resource "null_resource" "build_hello" {
  triggers = {
    # timestamp() にすると毎回ビルド
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${local.build_output}
      cd ${local.lambda_src_path} && \
      GOOS=linux GOARCH=amd64 go build -o ${local.build_output}/bootstrap .
      chmod +x ${local.build_output}/bootstrap
    EOT
  }
}

# ② デプロイのため、ビルド済みバイナリを zip 化
data "archive_file" "hello" {
  type        = "zip"
  source_file = "${local.build_output}/bootstrap"
  # Terraform の archive_file がデプロイ用に行う
  output_path = "${local.build_output}/hello.zip"

  depends_on = [null_resource.build_hello]
}

# ③ SAM CLI への案内板（これがないと sam local invoke が動かない）
resource "null_resource" "sam_metadata_aws_lambda_function_hello" {
  triggers = {
    resource_name        = "aws_lambda_function.hello"
    resource_type        = "ZIP_LAMBDA_FUNCTION"
    original_source_code = local.lambda_src_path
    # SAM CLI は built_output_pathディレクトリを読む
    built_output_path = local.build_output
  }

  depends_on = [null_resource.build_hello]
}

# ④ Lambda 関数本体（普通の定義と同じ）
resource "aws_lambda_function" "hello" {
  filename         = data.archive_file.hello.output_path
  function_name    = "hello-function"
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  role             = aws_iam_role.lambda.arn
  source_code_hash = data.archive_file.hello.output_base64sha256

  depends_on = [null_resource.build_hello]
}
