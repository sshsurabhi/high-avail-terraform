terraform {
  required_providers {
      aws = {
            source = "hashicorp/aws"
              version = "~> 5.0"
              }
                }
            }
            # the aws region where we want to deploy our various resources
provider "aws" {
    region     = var.region
    access_key = var.access_key
    secret_key = var.secret_key
            }
