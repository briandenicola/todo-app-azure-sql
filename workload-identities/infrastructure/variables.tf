variable "certificate_name" {
  description   = "The name of the PFX file"
  type          = string
  default       = "my-wildcard-cert.pfx"
}

variable "namespace" {
  description   = "The namespace for the workload identity"
  type          = string
  default       = "default"
}

variable "vm_sku" {
  description = "The VM type for the system node pool"
  default     = "Standard_D4ads_v5"
}