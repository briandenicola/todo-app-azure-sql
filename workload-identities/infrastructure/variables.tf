variable "certificate_password" {
  description   = "Password for the PFX file"
  type          = string
}

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