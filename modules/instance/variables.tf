variable "cluster_size" {
    default = 3
}

variable "cluster_name" {
    default = "instance"
}

variable "network_name" {
    default = "internal"
}

variable "floatingip_pool" {
    default = "external"
}

variable "image" { }
variable "user_data" { }
variable "key_pair" { }

variable "sec_group" {
    type = "list"
}

variable "flavor" {
    default = "m1.large"
}

variable "volume_size" {
    default = 40
}

variable "public_key_path" {
    description = "The path of the ssh pub key"
    default = "~/.ssh/id_rsa.pub"
}
