variable "repository_name" {
  description = "ECR repository name"
  type        = string
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "keep_tagged_count" {
  description = "Number of tagged images to retain"
  type        = number
  default     = 10
}
