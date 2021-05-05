#
# Configure the S3 backend, which needs to be set up separately
#
terraform {
  backend "s3" {
    region     = "eu-west-1"
    bucket         = "seobooker.tf-dev-infra-state"
    key            = "api/notifications-api/terraform.tfstate"
    dynamodb_table = "seobooker_dev_infra"
  }
}


data "aws_cognito_user_pools" "selected" {
  name = var.cognito_user_pool_name
}


# Configure the AWS Provider
provider "aws" {
  region = var.region
}

#
# Set up the api resources
#
module api {
  source = "../../modules/api"
  region = var.region
  stage = var.stage
  prefix = var.prefix
  account_id = var.account_id
  api_name = var.api_name
  runtime = var.runtime
  root_domain = var.root_domain
  cognito_user_pool_name = var.cognito_user_pool_name
  cognito_user_pool_id = var.cognito_user_pool_id
  userpool_id = var.userpool_id
}

# module ses {
#   source = "../../modules/ses"
#   region = var.region
#   prefix = var.prefix
# }