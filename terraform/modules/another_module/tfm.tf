#######################################################
# tf-manage metadata
#######################################################
variable "tfm_product" {
  default     = ""
  description = "Product name"
  type        = string
}

variable "tfm_repo" {
  default     = ""
  description = "Repository name"
  type        = string
}

variable "tfm_module" {
  default     = ""
  description = "Module name"
  type        = string
}

variable "tfm_env" {
  default     = ""
  description = "Environment"
  type        = string
}

variable "tfm_module_instance" {
  default     = ""
  description = "Module instance"
  type        = string
}
