resource "null_resource" "discovery_url_template" {
    provisioner "local-exec" {
        command = "curl -s 'https://discovery.etcd.io/new?size=${var.nomad_server_count}' > ${var.discovery_url_file}"
    }
}
resource "template_file" "discovery_url" {
    template = "${var.discovery_url_file}"
    depends_on = ["null_resource.discovery_url_template"]
}

resource "template_file" "nomad_server_cloud_config" {
    template = "${file("templates/nomad_server_cloud_config.yaml")}"
    vars {
        "etcd_discovery_url" = "${template_file.discovery_url.rendered}"
        "cluster_size" = "${var.nomad_server_count}"
        "fleet_tags" = "nomad-server,consul-server"
        "consul_master_token" = "${var.consul_master_token}"
    }
}

module "nomad_server" {
    source = "./modules/instance"
    cluster_name = "${var.username}-nomad-server"
    user_data = "${template_file.nomad_server_cloud_config.rendered}"
    key_pair = "${openstack_compute_keypair_v2.nomad.name}"
    sec_group = [
        "${openstack_compute_secgroup_v2.nomad_cluster.name}",
        "${openstack_compute_secgroup_v2.consul_ui.name}"
    ]
    # defaults in variables.tf
    cluster_size = "${var.nomad_server_count}"
    image = "${var.image}"
    flavor = "m1.small"
}

output "consul_ui" {
    value = "${join(",", formatlist("http://%s:8500", split(",", module.nomad_server.public_ips)))}"
}

output "nomad_servers_private_ips" {
    value = "${module.nomad_server.private_ips}"
}

output "nomad_servers_public_ips" {
    value = "${module.nomad_server.public_ips}"
}
