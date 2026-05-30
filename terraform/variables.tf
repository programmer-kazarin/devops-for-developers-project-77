variable "vm_password" {
  description = "SSH password for user student on lab VMs"
  type        = string
  default     = "student"
  sensitive   = true
}
