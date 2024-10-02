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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = string
}

variable "region" {
  description = "Azure region to deploy to"
  default     = "canadaeast"
}

variable "zones" {
  description = "The zones to deploy the cluster to"
  type        = list(string)
  default     = ["1", "2", "3"]
}
