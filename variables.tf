variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "environment" {}


variable "cidr_vpc" {
  description = "VPC's CIDR"
  default = "10.1.0.0/16"
}

variable "cidr_public_subnet_a" {
  description = "CIDR of public Subnet a"
  default = "10.1.0.0/24"

}

variable "cidr_public_subnet_b" {
  description = "CIDR of public subnet b"
  default = "10.1.1.0/24"

}

variable "cidr_app_subnet_a" {
  description = "CIDR of private Subnet a"
  default = "10.1.2.0/24"

}

variable "cidr_app_subnet_b" {
  description = "CIDR of private Subnet b"
  default = "10.1.3.0/24"

}



variable "az_a" {
  description = "availability zone a"
  default = "eu-west-3a"
}


variable "az_b" {
  description = "availability zone b"
  default = "eu-west-3b"

}
