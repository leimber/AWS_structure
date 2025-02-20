terraform {
  backend "s3" {
    bucket         = "lab4-tfstate"      
    key            = "terraform.tfstate"
    region         = "eu-west-3"         
    dynamodb_table = "lab4-tf-lock"      
  }
}