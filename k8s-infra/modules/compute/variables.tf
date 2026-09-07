variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "environment" { type = string }
variable "ssh_public_key_path" { type = string }
variable "target_group_arn" { type = string }
