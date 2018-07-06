resource "aws_lambda_function" "AMI-Backup" 
{
  function_name = "AMI-Backup"
  handler = "lambda_function.lambda_handler"
  role = "${aws_iam_role.lambda_exec_role.arn}"
  runtime = "python2.7"
  filename = "/home/ubuntu/terraform/AMI_backup_cleanup/backup.zip"
  environment 
  {
    variables =
      {
      AWS_ACCOUNT_NUMBER = "${data.aws_caller_identity.current.account_id}"
      RETENTION_DAYS     = "7" 
      }
  }
}

resource "aws_cloudwatch_event_rule" "backup-event"
{
  depends_on = ["aws_lambda_function.AMI-Backup"]
  name = "AMI-Backup-event"
  description = "AMI Backup Event"
  schedule_expression = "cron(30 18 ? * * *)"
}

resource "aws_cloudwatch_event_target" "lambda-to-event"
 {
    rule = "${aws_cloudwatch_event_rule.backup-event.name}"
    target_id = "backup"
    arn = "${aws_lambda_function.AMI-Backup.arn}"
}

resource "aws_lambda_permission" "lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.AMI-Backup.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.backup-event.arn}"
}
