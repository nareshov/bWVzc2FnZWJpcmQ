###
# Variables
#

variable "do_token" {
  description = "DigitalOcean Personal Access Token"
}

variable "ssh_pub_key" {
  description = "Path to local SSH pub key"
}

#variable "ssh_pvt_key" {
#  description = "Path to local SSH pvt key"
#}

###
# Provider
#

provider "digitalocean" {
  token = "${var.do_token}"
}

###
# Resources
#
resource "digitalocean_ssh_key" "default" {
  name       = "SSH key for prometheus droplet"
  public_key = "${file(var.ssh_pub_key)}"
}

resource "digitalocean_droplet" "prometheus" {
  image    = "ubuntu-18-10-x64"
  name     = "prometheus-1"
  region   = "fra1"
  size     = "s-1vcpu-1gb"                                   // "1GB RAM; 1 CPU; 25GB SSD - $5/mo"
  ssh_keys = ["${digitalocean_ssh_key.default.fingerprint}"]

  provisioner "local-exec" {
    command    = "sleep 40"
    on_failure = "continue"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install python",
    ]
  }

  connection {
    user        = "root"
    type        = "ssh"
    timeout     = "2m"
  }
}

data "template_file" "hosts" {
  template = "${file("hosts.tpl")}"

  vars {
    prometheus_ipv4 = "${digitalocean_droplet.prometheus.ipv4_address}"
  }
}

# This populates the ansible inventory file
resource "null_resource" "update_hosts" {
  triggers {
    template = "${data.template_file.hosts.rendered}"
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.hosts.rendered}' > hosts"
  }
}
