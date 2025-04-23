provider "aws" {
    region = "eu-north-1"
   
}

provider "aws" {
    alias = "secondary"
    region = "us-east-1"
  
}