variable "gcp_project" {
    type = string
}

variable "key_path" {
    type = string
}

variable "project_zone" {
    type = string
}

variable "region" {
    type = string
}

variable "instances_names" {
    type = list(string)
}

variable "ssh_path" {
    type = string
}

variable "ssh_private_key_path" {
  type = string
}

variable "firewall_object" {
    type = list(object({
        name = string
        direction = string
        ports = list(string)
        protocol = string
        source_ranges = list(string)
        target_tags = list(string)
        priority = number
    }))
}