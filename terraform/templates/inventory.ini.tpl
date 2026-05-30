# Сгенерировано Terraform (terraform/ansible.tf). Не редактировать вручную.
[webservers]
server1 ansible_host=${server1_ip} ansible_user=${vm_user}
server2 ansible_host=${server2_ip} ansible_user=${vm_user}

[balancer]
balancer01 ansible_host=${balancer_ip} ansible_user=${vm_user}

[postgres]
postgres01 ansible_host=${db_ip} ansible_user=${vm_user}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
