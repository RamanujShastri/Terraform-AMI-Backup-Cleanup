resource "aws_lambda_function" "AMI-Cleanup" 
{
  function_name = "AMI-Cleanup"
  handler = "lambda_function.lambda_handler"
  role = "${aws_iam_role.lambda_exec_role.arn}"
  runtime = "python2.7"
  filename = "/home/ubuntu/terraform/AMI_backup_cleanup/cleanup.zip"
  environment 
  {
    variables =
      {
      AWS_ACCOUNT_NUMBER = "${data.aws_caller_identity.current.account_id}"
      }
  }
}

resource "aws_cloudwatch_event_rule" "cleanup-event"
{
  depends_on = ["aws_lambda_function.AMI-Cleanup"]
  name = "AMI-Cleanup-event"
  description = "AMI Cleanup Event"
  schedule_expression = "cron(30 19 ? * * *)"
}

resource "aws_cloudwatch_event_target" "lambda-to-event2"
 {
    rule = "${aws_cloudwatch_event_rule.cleanup-event.name}"
    target_id = "cleanup"
    arn = "${aws_lambda_function.AMI-Cleanup.arn}"
}

resource "aws_lambda_permission" "lambda2" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.AMI-Cleanup.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.cleanup-event.arn}"
}
