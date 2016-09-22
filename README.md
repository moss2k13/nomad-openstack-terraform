# Nomad on CoreOS terraformed on OpenStack

Based on:
- [xuwang/gcp-nomad](https://github.com/xuwang/gcp-nomad)
- [paulczar/terraform-kubernetes-openstack](https://github.com/paulczar/terraform-kubernetes-openstack)
- [Sander Knape blog](https://sanderknape.com/2016/08/nomad-consul-multi-datacenter-container-orchestration)

## Status

Ready for testing. By default it will install 3 nomad servers (m1.small) and 2 nomad clients (m1.large).

Verified with below versions:
- nomad 0.4.0
- consul 0.6.4
- coreos 1122.2
- terraform 0.7.3
- keystone v2.0

## Prepare

- [Install Terraform](https://www.terraform.io/intro/getting-started/install.html)
- [Upload a CoreOS image to glance](https://coreos.com/os/docs/latest/booting-on-openstack.html)

Code assumes default devstack networks:

- network name: [internal](https://github.com/moss2k13/nomad-openstack-terraform/blob/master/modules/instance/variables.tf#L9)
- floating pool: [external](https://github.com/moss2k13/nomad-openstack-terraform/blob/master/modules/instance/variables.tf#L13)
- region: RegionOne

## Usage

```
source ~/.stackrc
unset OS_PROJECT_DOMAIN_ID OS_USER_DOMAIN_ID OS_IDENTITY_API_VERSION
export OS_AUTH_URL=http://controller:5000/v2.0
git clone https://github.com/moss2k13/nomad-openstack-terraform.git
cd nomad-openstack-terraform
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa
terraform get
export MY_IP=$(curl -s icanhazip.com)
terraform plan -var "auth_url=$OS_AUTH_URL" -var "username=$OS_USERNAME" -var "password=$OS_PASSWORD" -var "project=$OS_PROJECT_NAME" -var "whitelist_network=${MY_IP}/32"
terraform apply -var "auth_url=$OS_AUTH_URL" -var "username=$OS_USERNAME" -var "password=$OS_PASSWORD" -var "project=$OS_PROJECT_NAME" -var "whitelist_network=${MY_IP}/32"

Apply complete! Resources: 17 added, 0 changed, 0 destroyed.

Outputs:

consul_ui = http://78.133.133.31:8500,http://78.133.133.34:8500,http://78.133.133.32:8500
nomad_client_private_ips = 172.16.1.46,172.16.1.47
nomad_client_public_ips = 78.133.133.33,78.133.133.35
nomad_servers_private_ips = 172.16.1.43,172.16.1.44,172.16.1.45
nomad_servers_public_ips = 78.133.133.31,78.133.133.34,78.133.133.32
```

You should see all services and nodes green under consul urls. 

## Next steps

Let's run an example nomad job now:

```
$ ssh -A core@78.133.133.31
core@mossapio-nomad-server-1 ~ $ nomad server-members
Name                                              Address      Port  Status  Leader  Protocol  Build  Datacenter  Region
mossapio-nomad-server-1.openstacklocal.RegionOne  172.16.1.43  4648  alive   false   2         0.4.0  os          RegionOne
mossapio-nomad-server-2.openstacklocal.RegionOne  172.16.1.44  4648  alive   true    2         0.4.0  os          RegionOne
mossapio-nomad-server-3.openstacklocal.RegionOne  172.16.1.45  4648  alive   false   2         0.4.0  os          RegionOne

core@mossapio-nomad-server-1 ~ $ nomad node-status
ID        DC  Name                                    Class   Drain  Status
a2fda72b  os  mossapio-nomad-client-1.openstacklocal  <none>  false  ready
09f90cba  os  mossapio-nomad-client-2.openstacklocal  <none>  false  ready

core@mossapio-nomad-server-1 ~ $ consul members
Node                                    Address           Status  Type    Build  Protocol  DC
mossapio-nomad-client-1.openstacklocal  172.16.1.46:8301  alive   client  0.6.4  2         os
mossapio-nomad-client-2.openstacklocal  172.16.1.47:8301  alive   client  0.6.4  2         os
mossapio-nomad-server-1.openstacklocal  172.16.1.43:8301  alive   server  0.6.4  2         os
mossapio-nomad-server-2.openstacklocal  172.16.1.44:8301  alive   server  0.6.4  2         os
mossapio-nomad-server-3.openstacklocal  172.16.1.45:8301  alive   server  0.6.4  2         os

core@mossapio-nomad-server-1 ~ $ cat nginx.nomad 
job "nginx" {
  region = "RegionOne"
  datacenters = ["os"]

  group "webserver" {
    count = 4

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"

      mode = "delay"
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:latest"
        port_map {
          web = 80
        }
      }

      service {
        name = "nginx"
        port = "web"
        check {
          name = "alive"
          type = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        cpu = 500 # 500 Mhz
        memory = 64 # 64MB
        network {
          mbits = 10
          port "web" {
          }
        }
      }
    }
  }
}

core@mossapio-mossapio-nomad-server-1 ~ $ nomad validate nginx.nomad 
Job validation successful

core@mossapio-mossapio-nomad-server-1 ~ $ nomad plan nginx.nomad 
+ Job: "nginx"
+ Task Group: "webserver" (4 create)
  + Task: "nginx" (forces create)

Scheduler dry-run:
- All tasks successfully allocated.

Job Modify Index: 0
To submit the job with version verification run:

nomad run -check-index 0 nginx.nomad

When running the job with the check-index flag, the job will only be run if the
server side version matches the the job modify index returned. If the index has
changed, another user has modified the job and the plan's results are
potentially invalid.

core@mossapio-nomad-server-1 ~ $ nomad run nginx.nomad                                                                                                                                           
==> Monitoring evaluation "f576c00f"
    Evaluation triggered by job "nginx"
    Allocation "2515405f" created: node "7d1f4864", group "webserver"
    Allocation "4dacac61" created: node "0458a322", group "webserver"
    Allocation "eeeb45f4" created: node "7d1f4864", group "webserver"
    Allocation "1e91b3a9" created: node "0458a322", group "webserver"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "f576c00f" finished with status "complete"

core@mossapio-nomad-server-1 ~ $ nomad status 
ID     Type     Priority  Status
nginx  service  50        running

core@mossapio-nomad-server-1 ~ $ nomad status nginx
ID          = nginx
Name        = nginx
Type        = service
Priority    = 50
Datacenters = os
Status      = running
Periodic    = false

Allocations
ID        Eval ID   Node ID   Task Group  Desired  Status
9542e1b4  0a01b528  0458a322  webserver   run      running
32d87ce3  0a01b528  0458a322  webserver   run      running
509aff62  0a01b528  7d1f4864  webserver   run      running
6936eeac  0a01b528  7d1f4864  webserver   run      running

# nomad-client pov
core@mossapio-nomad-client-1 ~ $ dkm
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx               latest              4a88d06e26f4        5 days ago          183.5 MB
core@mossapio-nomad-client-1 ~ $ dkc 
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                                           NAMES
2e93cc32782c        nginx:latest        "nginx -g 'daemon off"   7 minutes ago       Up 7 minutes        443/tcp, 172.16.1.46:29219->80/tcp, 172.16.1.46:29219->80/udp   nginx-44c4037c-6f0f-36b6-511f-46a546f6d348
d095b9127809        nginx:latest        "nginx -g 'daemon off"   7 minutes ago       Up 7 minutes        443/tcp, 172.16.1.46:48107->80/tcp, 172.16.1.46:48107->80/udp   nginx-8b518a06-e01b-a28d-252d-b5bff411ce62
# end nomad-client pov
	   
core@mossapio-nomad-client-1 ~ $ nomad alloc-status 18f21508
ID            = 18f21508
Eval ID       = 05a336be
Name          = nginx.webserver[0]
Node ID       = 09f90cba
Job ID        = nginx
Client Status = running

Task "nginx" is "running"
Task Resources
CPU    Memory          Disk     IOPS  Addresses
0/500  1.3 MiB/64 MiB  300 MiB  0     web: 172.16.1.47:48038

Recent Events:
Time                   Type      Description
09/21/16 13:05:52 UTC  Started   Task started by client
09/21/16 13:05:30 UTC  Received  Task received by client

core@mossapio-nomad-client-1 ~ $ curl 172.16.1.47:48038
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

core@mossapio-nomad-server-1 ~ $ nomad stop nginx
==> Monitoring evaluation "ae375eab"
    Evaluation triggered by job "nginx"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "ae375eab" finished with status "complete"
```

## Clean up
```
terraform destroy -var "auth_url=$OS_AUTH_URL" -var "username=$OS_USERNAME" -var "password=$OS_PASSWORD" -var "project=$OS_PROJECT_NAME" -var "whitelist_network=${MY_IP}/32"

Enter a value: yes
```
