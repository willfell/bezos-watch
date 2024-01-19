resource "null_resource" "sam_deploy" {
  provisioner "local-exec" {
    command = <<EOT
        cd ${path.module}/Sam
        sam build
        sam deploy --parameter-overrides \
        "ParameterKey=SLACKTOKENSECRET,ParameterValue=${var.slack_token_secret_name} \
        ParameterKey=SLACKTOKENSECRETARN,ParameterValue=${var.slack_token_secret_arn} \
        ParameterKey=SLACKCHANNEL,ParameterValue=${var.slack_channel} \
        ParameterKey=LOGGROUP,ParameterValue=${var.name}" \
        --no-fail-on-empty-changeset
    EOT
  }

  triggers = {
    #always_run = timestamp()
    template_checksum = data.local_file.sam_template.id
    code_checksum     = data.local_file.lambda_code.id
  }
}

