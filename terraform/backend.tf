terraform {
  cloud {
    organization = "RentRahisi"

    workspaces {
      name = "node-app"
    }
  }

  required_providers {
    aws = {
      version = ">= 4.59.0"
    }
  }
}
