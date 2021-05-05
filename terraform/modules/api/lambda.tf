###################################
# notifications-api-authorizer lambda function
###################################

resource "aws_iam_role" "notifications-api-authorizer-invocation-role" {
  name = "${var.prefix}-notifications-api-authorizer-invocation-role-${var.stage}"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "notifications-api-authorizer-invocation-policy" {
  name = "${var.prefix}-notifications-api-authorizer-invocation-policy-${var.stage}"
  role = aws_iam_role.notifications-api-authorizer-invocation-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.notifications-api-authorizer.arn}"
    }
  ]
}
EOF
}


# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "notifications-api-authorizer-role" {
  name = "${var.prefix}-notifications-api-authorizer-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "notifications-api-authorizer-policy" {
    name        = "${var.prefix}-notifications-api-authorizer-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "notifications-api-authorizer-attach" {
    role       = aws_iam_role.notifications-api-authorizer-role.name
    policy_arn = aws_iam_policy.notifications-api-authorizer-policy.arn
}

resource "aws_lambda_function" "notifications-api-authorizer" {
  function_name = "${var.prefix}-notifications-api-authorizer-${var.stage}"

  # The zip containing the lambda function
  filename    = "../../../lambda/dist/functions/api-authorizer.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/api-authorizer.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = var.runtime
  timeout = 10

  role = aws_iam_role.notifications-api-authorizer-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      userpool_id = var.cognito_user_pool_id
    }
  }
}

###################################
# send-email-notification lambda function
###################################

resource "aws_lambda_function" "send-new-event-notification" {
  function_name = "${var.prefix}-send-new-event-notification-${var.stage}"

  # The bucket name created by the initial infrastructure set up
  filename    = "../../../lambda/dist/functions/new-event.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/new-event.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = "nodejs12.x"
  timeout = 10
  role = aws_iam_role.send-new-event-notification-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [
    aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      userpool_id = var.userpool_id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "send-new-event-notification-role" {
  name = "${var.prefix}-send-new-event-notification-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "send-new-event-notification-policy" {
    name        = "${var.prefix}-send-new-event-notification-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "cognito-idp:AdminGetUser"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:cognito-idp:${var.region}:${var.account_id}:userpool/${var.userpool_id}"
    },
    {
      "Action": [
        "ses:SendTemplatedEmail"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "send-new-event-notification-attach" {
    role       = aws_iam_role.send-new-event-notification-role.name
    policy_arn = aws_iam_policy.send-new-event-notification-policy.arn
}

resource "aws_lambda_permission" "send-new-event-notification-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send-new-event-notification.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.notifications-api.execution_arn}/*/*"
}

###################################
# send-email-notification lambda function
###################################

resource "aws_lambda_function" "send-new-application-notification" {
  function_name = "${var.prefix}-send-new-application-notification-${var.stage}"

  # The bucket name created by the initial infrastructure set up
  filename    = "../../../lambda/dist/functions/new-application.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/new-application.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = "nodejs12.x"
  timeout = 10
  role = aws_iam_role.send-new-event-notification-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [
    aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      userpool_id = var.userpool_id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "send-new-application-notification-role" {
  name = "${var.prefix}-send-new-application-notification-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "send-new-application-notification-policy" {
    name        = "${var.prefix}-send-new-application-notification-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "cognito-idp:AdminGetUser"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:cognito-idp:${var.region}:${var.account_id}:userpool/${var.userpool_id}"
    },
    {
      "Action": [
        "ses:SendTemplatedEmail"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ses:${var.region}:${var.account_id}:identity/${var.root_domain}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "send-new-application-notification-attach" {
    role       = aws_iam_role.send-new-application-notification-role.name
    policy_arn = aws_iam_policy.send-new-application-notification-policy.arn
}

resource "aws_lambda_permission" "send-new-application-notification-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send-new-application-notification.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.notifications-api.execution_arn}/*/*"
}

###################################
# send-email-notification lambda function
###################################

resource "aws_lambda_function" "send-welcome-notification" {
  function_name = "${var.prefix}-send-welcome-notification-${var.stage}"

  # The bucket name created by the initial infrastructure set up
  filename    = "../../../lambda/dist/functions/welcome.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/welcome.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = "nodejs12.x"
  timeout = 10
  role = aws_iam_role.send-welcome-notification-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [
    aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      userpool_id = var.userpool_id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "send-welcome-notification-role" {
  name = "${var.prefix}-send-welcome-notification-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "send-welcome-notification-policy" {
    name        = "${var.prefix}-send-welcome-notification-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "cognito-idp:AdminGetUser"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:cognito-idp:${var.region}:${var.account_id}:userpool/${var.userpool_id}"
    },
    {
      "Action": [
        "ses:SendTemplatedEmail"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "send-welcome-notification-attach" {
    role       = aws_iam_role.send-welcome-notification-role.name
    policy_arn = aws_iam_policy.send-welcome-notification-policy.arn
}

resource "aws_lambda_permission" "send-welcome-notification-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send-welcome-notification.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.notifications-api.execution_arn}/*/*"
}

###################################
# send-email-notification lambda function
###################################

resource "aws_lambda_function" "send-event-selection-notification" {
  function_name = "${var.prefix}-send-event-selection-notification-${var.stage}"

  # The bucket name created by the initial infrastructure set up
  filename    = "../../../lambda/dist/functions/event-selection.zip"
  source_code_hash = filebase64sha256("../../../lambda/dist/functions/event-selection.zip")

  # "index" is the filename within the zip file (index.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "index.handler"
  runtime = "nodejs12.x"
  timeout = 10
  role = aws_iam_role.send-event-selection-notification-role.arn

  // The run time environment dependencies (package.json & node_modules)
  layers = [
    aws_lambda_layer_version.lambda_layer.id]

  environment {
    variables = {
      region =  var.region,
      userpool_id = var.userpool_id
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "send-event-selection-notification-role" {
  name = "${var.prefix}-send-event-selection-notification-role-${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "send-event-selection-notification-policy" {
    name        = "${var.prefix}-send-event-selection-notification-policy-${var.stage}"
    description = ""
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Action": [
        "cognito-idp:AdminGetUser"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:cognito-idp:${var.region}:${var.account_id}:userpool/${var.userpool_id}"
    },
    {
      "Action": [
        "ses:SendTemplatedEmail"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "send-event-selection-notification-attach" {
    role       = aws_iam_role.send-event-selection-notification-role.name
    policy_arn = aws_iam_policy.send-event-selection-notification-policy.arn
}

resource "aws_lambda_permission" "send-event-selection-notification-apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send-event-selection-notification.arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.notifications-api.execution_arn}/*/*"
}