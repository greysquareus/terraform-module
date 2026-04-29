terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.42.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}


module "instance" {
  source        = "../../server"
  region        = "us-east-2"
  instance_type = "t2.micro"
  key_name      = "mykey-stage"
  subnet_id     = module.network.subnet_id
  sec_group_id  = module.network.sec_group_id
}

module "network" {
  source = "../../network"
  ports  = [22, 80, 443, 8080, 9090]
  env    = "stage"
}

resource "aws_eip_association" "eip_association" {
  instance_id   = module.instance.instance_id
  allocation_id = module.network.eip_id
}