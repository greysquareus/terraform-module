variable "ports" {
  type = list(number)
}

variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.env)
    error_message = "env must be something from there [stage, prod, dev]"
  }
}
