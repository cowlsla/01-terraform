variable "number_example" {
  type        = number
  default     = 100
}

variable "string_example" {
  type        = string
  default     = "terraform-example-instance"
}

variable "list_example" {
  type        = list(string)
  default     = ["a", "b", "c"]
}
