variable "project_name" {
  description = "proyecto final hackaboss aws"
  type        = string
  default     = "lab4_final"      
}

variable "tags" {
  description = "Tags de los servicios"
  type        = map(string)
  default = {
    Project   = "lab4"            
    Terraform = "true"            
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"  
}

variable "domain_name" {
  description = "Nombre del dominio interno"
  type        = string
  default     = "lab4.internal"
}