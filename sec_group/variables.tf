variable "name" {}
variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}
variable "ingress" {
  type = list(object({
    from            = number
    to              = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []
}
