terraform {
  backend "remote" {
    organization = "RentRahisi"

    workspaces {
      name = "node-app"
    }
  }

  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      version = ">= 4.59.0"
    }
  }
}
