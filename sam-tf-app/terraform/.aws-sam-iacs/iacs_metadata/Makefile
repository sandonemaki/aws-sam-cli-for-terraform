build-AwsLambdaFunctionHelloEEEE9573:
	python3 ".aws-sam-iacs/iacs_metadata/copy_terraform_built_artifacts.py" --expression "|values|root_module|resources|[?address==\"null_resource.sam_metadata_aws_lambda_function_hello\"]|values|triggers|built_output_path" --directory "$(ARTIFACTS_DIR)" --target "null_resource.sam_metadata_aws_lambda_function_hello"
