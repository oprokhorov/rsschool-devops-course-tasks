terraform {
  backend "s3" {
    bucket       = "terraform-state-bucket-87f4"
    key          = "state/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # this replaces dynamodb locking, which is being deprecated soon
  }
}
