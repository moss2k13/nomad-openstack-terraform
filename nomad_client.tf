resource "template_file" "nomad_client_cloud_config" {
    template = "${file("templates/nomad_client_cloud_config.yaml")}"
    vars {
        "consul_address" = "${module.nomad_server.first_private_ip}"
        "consul_master_token" = "${var.consul_master_token}"
    }
}

module "nomad_client" {
    source = "./modules/instance"
    cluster_name = "${var.username}-nomad-client"
    user_data = "${template_file.nomad_client_cloud_config.rendered}"
    key_pair = "${openstack_compute_keypair_v2.nomad.name}"
    sec_group = [
        "${openstack_compute_secgroup_v2.nomad_cluster.name}"
    ]
    # defaults in variables.tf
    cluster_size = "${var.nomad_client_count}"
    image = "${var.image}"
}

output "nomad_client_public_ips" {
    value = "${module.nomad_client.public_ips}"
}

output "nomad_client_private_ips" {
    value = "${module.nomad_client.private_ips}"
}
