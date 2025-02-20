variable "project_name" {
  description = "poryyecto final hackaboss aws"
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