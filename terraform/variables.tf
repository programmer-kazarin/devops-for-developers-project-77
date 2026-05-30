variable "vm_password" {
  description = "SSH password for user student on lab VMs"
  type        = string
  default     = "student"
  sensitive   = true
}

variable "datadog_api_key" {
  description = "DataDog API key (Organization Settings → API Keys)"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "DataDog Application key (Organization Settings → Application Keys)"
  type        = string
  sensitive   = true
}

variable "datadog_api_url" {
  description = "DataDog API URL (EU: datadoghq.eu, US: datadoghq.com)"
  type        = string
  default     = "https://api.datadoghq.eu/"
}
