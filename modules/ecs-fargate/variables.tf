variable "cluster_name"          { type = string }
variable "service_name"          { type = string }
variable "image"                 { type = string }
variable "cpu"                   { type = number; default = 512 }
variable "memory"                { type = number; default = 1024 }
variable "desired_count"         { type = number; default = 2 }
variable "container_port"        { type = number }
variable "region"                { type = string; default = "ap-south-1" }
variable "vpc_id"                { type = string }
variable "subnet_ids"            { type = list(string) }
variable "alb_security_group_id" { type = string }
