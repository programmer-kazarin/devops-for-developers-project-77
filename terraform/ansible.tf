resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.ini.tpl", {
    vm_user     = local.vm_user
    balancer_ip = local.vms["balancer"].ip
    server1_ip  = local.vms["server1"].ip
    server2_ip  = local.vms["server2"].ip
    db_ip       = local.vms["db"].ip
  })
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"
}

resource "local_file" "ansible_group_vars_terraform" {
  content = templatefile("${path.module}/templates/terraform_group_vars.yml.tpl", {
    gateway     = local.gateway
    balancer_ip = local.vms["balancer"].ip
    server1_ip  = local.vms["server1"].ip
    server2_ip  = local.vms["server2"].ip
    db_ip       = local.vms["db"].ip
  })
  filename        = "${path.module}/../ansible/group_vars/terraform.yml"
  file_permission = "0644"
}
