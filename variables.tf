variable "discovery_url_file" {
    default = "templates/discovery_url"
}

variable "nomad_server_count" {
    default = 3
}

variable "nomad_client_count" {
    default = 2
}

variable "consul_master_token" {
    default = "_consul_master_token_"
}

variable "image" {
    default = "coreos-stable-1122.2"
}

variable "project" {
    description = "Your openstack project"
}

variable "username" {
    description = "Your openstack username"
}

variable "password" {
    description = "Your openstack password"
}

variable "auth_url" {
    description = "Your openstack auth URL"
}

variable "public_key_path" {
    description = "The path of the ssh pub key"
    default = "~/.ssh/id_rsa.pub"
}

variable "whitelist_network" {
    description = "The source network to access your cluster"
    default = "0.0.0.0/0"
}
