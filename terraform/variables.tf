variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = ""
}

variable "email_address" {
  description = "Email address to receive GuardDuty findings"
  type        = string
}
