terraform {
  backend "s3" {
    bucket       = "vprofile-devops-hoa-tfstate-ap-southeast-2"
    key          = "main/terraform.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
    encrypt      = true
  }
}
