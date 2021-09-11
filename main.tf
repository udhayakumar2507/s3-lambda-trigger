# Creating resource variable
variable "function_name" {}
variable "emailId" {}
variable "bucket" {}
variable "region" {}

variable "json_file" {}

# fetching current account id
data "aws_caller_identity" "current" {}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/python/main.py"
  output_path = "${path.module}/python/main.py.zip"
}

# Creating Lambda resource

resource "aws_lambda_function" "test_lambda" {
  function_name = var.function_name
  role          = aws_iam_role.iam_for_lambda.arn
  #   role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSRoleForLambda"
  handler  = "main.lambda_handler"
  runtime  = "python3.8"
  timeout  = 30
  filename = "${path.module}/python/main.py.zip"
  source_code_hash = filebase64sha256("${path.module}/python/main.py.zip")
  environment {
    variables = {
      SENDER    = var.emailId
      BUCKET    = var.bucket
      REGION    = var.region
      JSON_FILE = var.json_file
    }
  }
}
# Creating s3 resource for invoking to lambda function
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket
  acl    = "private"
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

# Adding S3 bucket as trigger to my lambda and giving the permissions
resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = aws_s3_bucket.bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.test_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    # filter_prefix       = "file-prefix"
    # filter_suffix       = "file-extension"
  }
}
resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.bucket.id}"
}

resource "aws_ses_email_identity" "example" {
  email = var.emailId
}
# output of lambda arn

output "arn" {
  value = aws_lambda_function.test_lambda.arn
}

