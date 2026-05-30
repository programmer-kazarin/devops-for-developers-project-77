# Корневой Makefile: SSH и делегирование в terraform/ и ansible/
# Из корня: make apply | make prepare
# Напрямую: make -C terraform plan | make -C ansible install

TF_DIR      := terraform
ANSIBLE_DIR := ansible

TF_TARGETS := init init-upgrade plan apply destroy setup-host fmt validate plan-datadog apply-datadog \
	vms-list vms-stop vms-start clean-lab-images destroy-force vm-resize-disks

ANSIBLE_TARGETS := install setup test prepare deploy_postgres deploy_wiki deploy_caddy deploy_datadog \
	vault_edit vault_view ansible-ping ssh-known-hosts ssh-copy-id inventory-example

.PHONY: $(TF_TARGETS) $(ANSIBLE_TARGETS) ssh_server1 ssh_server2 ssh_balanser ssh_postgres

$(TF_TARGETS):
	$(MAKE) -C $(TF_DIR) $@

$(ANSIBLE_TARGETS):
	$(MAKE) -C $(ANSIBLE_DIR) $@

ssh_server1:
	ssh student@192.168.100.11

ssh_server2:
	ssh student@192.168.100.12

ssh_balanser:
	ssh student@192.168.100.10

ssh_postgres:
	ssh student@192.168.100.13
