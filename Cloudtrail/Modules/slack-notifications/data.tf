data "local_file" "sam_template" {
  filename = "${path.module}/Sam/template.yaml"
}

data "local_file" "lambda_code" {
  filename = "${path.module}/Lambda-Function/app.py"
}
