#resource "openstack_blockstorage_volume_v2" "data" {
#  name = "${var.cluster_name}-data-${count.index + 1}"
#  size = "${var.volume_size}"
#  count = "${var.cluster_size}"
#}

resource "openstack_networking_floatingip_v2" "fip" {
  count = "${var.cluster_size}"
  pool = "${var.floatingip_pool}"
}

resource "openstack_compute_instance_v2" "instance" {
#  depends_on = ["openstack_blockstorage_volume_v2.data"]
  count = "${var.cluster_size}"
  name = "${var.cluster_name}-${count.index + 1}"
  image_name = "${var.image}"
  flavor_name = "${var.flavor}"
  user_data = "${var.user_data}"
  key_pair = "${var.key_pair}"
  security_groups = ["${var.sec_group}"]
  floating_ip = "${element(openstack_networking_floatingip_v2.fip.*.address, count.index)}"
  network {
    name = "${var.network_name}"
  }
#  volume {
#    volume_id = "${element(openstack_blockstorage_volume_v2.data.*.id, count.index)}"
#  }
}

output "instance_names" {
    value = "${join(",", openstack_compute_instance_v2.instance.*.name)}"
}

output "private_ips" {
    value = "${join(",", openstack_compute_instance_v2.instance.*.network.0.fixed_ip_v4)}"
}

output "public_ips" {
    value = "${join(",", openstack_networking_floatingip_v2.fip.*.address)}"
}

output "first_private_ip" {
    value = "${element(openstack_compute_instance_v2.instance.*.network.0.fixed_ip_v4, 0)}"
}
