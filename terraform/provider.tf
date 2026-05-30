terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8.0"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.43"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

locals {
  vm_user = "student"
  gateway = "192.168.100.1"
  ubuntu_image = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  # Образ cloud ~2.2 GiB — без увеличения корень заполняется при apt/docker
  vm_disk_bytes = 12 * 1024 * 1024 * 1024

  vms = {
    balancer = { memory = 512, vcpu = 1, ip = "192.168.100.10", mac = "52:54:00:10:00:0a" }
    server1  = { memory = 1024, vcpu = 1, ip = "192.168.100.11", mac = "52:54:00:10:00:0b" }
    server2  = { memory = 1024, vcpu = 1, ip = "192.168.100.12", mac = "52:54:00:10:00:0c" }
    db       = { memory = 2048, vcpu = 2, ip = "192.168.100.13", mac = "52:54:00:10:00:0d" }
  }
}

# Отдельный pool, чтобы destroy не конфликтовал с системным default и чужими файлами в images/
resource "libvirt_pool" "lab" {
  name = "devops-lab"
  type = "dir"

  target {
    path = "/var/lib/libvirt/images/devops-lab"
  }
}

resource "libvirt_network" "lab" {
  name      = "devops-lab-net"
  mode      = "nat"
  domain    = "lab.local"
  addresses = ["192.168.100.0/24"]
  autostart = true

  dhcp { enabled = true }
  dns {
    enabled    = true
    local_only = false
  }
}

# libvirt 0.8: size и source вместе нельзя — базовый образ + COW-тома 12 GiB
resource "libvirt_volume" "ubuntu_base" {
  name   = "devops-lab-ubuntu-base.qcow2"
  pool   = libvirt_pool.lab.name
  source = local.ubuntu_image
  format = "qcow2"
}

resource "libvirt_volume" "vm_disk" {
  for_each = local.vms

  name           = "devops-lab-${each.key}.qcow2"
  pool           = libvirt_pool.lab.name
  format         = "qcow2"
  size           = local.vm_disk_bytes
  base_volume_id = libvirt_volume.ubuntu_base.id
}

resource "libvirt_cloudinit_disk" "vm_init" {
  for_each = local.vms

  name = "devops-lab-${each.key}-cloudinit.iso"
  pool = libvirt_pool.lab.name

  meta_data = "instance-id: ${each.key}\nlocal-hostname: ${each.key}\n"

  user_data = <<-EOF
    #cloud-config
    hostname: ${each.key}
    growpart:
      mode: auto
      devices: ['/']
    ssh_pwauth: true
    chpasswd:
      list: |
        ${local.vm_user}:${var.vm_password}
      expire: false
    users:
      - name: ${local.vm_user}
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        lock_passwd: false
  EOF

  network_config = <<-EOF
    version: 2
    ethernets:
      eth0:
        match:
          macaddress: ${each.value.mac}
        dhcp4: false
        addresses:
          - ${each.value.ip}/24
        routes:
          - to: default
            via: ${local.gateway}
        nameservers:
          addresses: [${local.gateway}, 8.8.8.8]
  EOF
}

resource "libvirt_domain" "vm" {
  for_each = local.vms

  name   = "devops-lab-${each.key}"
  memory = each.value.memory
  vcpu   = each.value.vcpu

  cloudinit = libvirt_cloudinit_disk.vm_init[each.key].id

  disk {
    volume_id = libvirt_volume.vm_disk[each.key].id
  }

  network_interface {
    network_id = libvirt_network.lab.id
    mac        = each.value.mac
  }
}
