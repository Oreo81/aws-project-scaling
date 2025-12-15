variable "region" {
  default = "us-east-1"
}

variable "key_name" {
  default = "abes"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ami_id" {
  default = "ami-0dc2d3e4c0f9ebd18" # Amazon Linux 2 us-east-1
}
