variable "project" {
  type    = string
  default = "vprofile-devops"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "enable_nat" {
  type    = bool
  default = true
}

variable "alert_email" {
  type = string
}
