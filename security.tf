resource "openstack_compute_keypair_v2" "nomad" {
  name = "${var.username}-nomad"
  public_key = "${file(var.public_key_path)}"
}

resource "openstack_compute_secgroup_v2" "nomad_cluster" {
  name = "${var.username}-nomad-cluster"
  description = "nomad cluster base access"
  rule {
    ip_protocol = "tcp"
    from_port = "22"
    to_port = "22"
    cidr = "${var.whitelist_network}"
  }
  rule {
    ip_protocol = "icmp"
    from_port = "-1"
    to_port = "-1"
    self = true
  }
  rule {
    ip_protocol = "tcp"
    from_port = "1"
    to_port = "65535"
    self = true
  }
  rule {
    ip_protocol = "udp"
    from_port = "1"
    to_port = "65535"
    self = true
  }
}

resource "openstack_compute_secgroup_v2" "consul_ui" {
  name = "${var.username}-consul-ui"
  description = "consul ui access"
  rule {
    ip_protocol = "tcp"
    from_port = "8500"
    to_port = "8500"
    cidr = "${var.whitelist_network}"
  }
}
