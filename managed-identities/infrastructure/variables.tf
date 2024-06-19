variable "certificate_name" {
  description = "The name of the PFX file"
  type        = string
  default     = "my-wildcard-cert.pfx"
}

variable "vm_sku" {
  description = "The VM type for the VM"
  default     = "Standard_B1ms"
}

variable "region" {
  description = "value for the region"
  default     = "southcentralus"
}
