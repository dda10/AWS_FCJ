provider "aws" {
  region = var.region
}

terraform {
  cloud {
    organization = "anhdd-private-org"
    hostname     = "app.terraform.io" # Optional; defaults to app.terraform.io

    workspaces {
      project = "AWS_FCJ"

      tags = {
        source = "cli"
      }
    }
  }
}
