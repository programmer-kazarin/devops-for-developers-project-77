SSH_USER ?= student
SSH_KEY  ?= $(HOME)/.ssh/id_ed25519
SSH_OPTS ?= -o StrictHostKeyChecking=accept-new -i $(SSH_KEY)
TF_DIR     := terraform
VIRSH      := virsh -c qemu:///system
VM_NAMES   := balancer server1 server2 db
VM_PREFIX  := devops-lab

.PHONY: setup plan apply destroy vms-list vms-stop vms-start \
	ssh-balancer ssh-server1 ssh-server2 ssh-db

setup:
	cd $(TF_DIR) && terraform init
	@grep -q '^dynamic_ownership' /etc/libvirt/qemu.conf 2>/dev/null || \
		echo 'dynamic_ownership = 1' | sudo tee -a /etc/libvirt/qemu.conf
	@sudo sed -i 's/^#\?dynamic_ownership.*/dynamic_ownership = 1/' /etc/libvirt/qemu.conf
	@grep -q '^security_driver' /etc/libvirt/qemu.conf 2>/dev/null || \
		echo 'security_driver = "none"' | sudo tee -a /etc/libvirt/qemu.conf
	@sudo sed -i 's/^#\?security_driver.*/security_driver = "none"/' /etc/libvirt/qemu.conf
	sudo systemctl restart libvirtd
	sudo usermod -aG libvirt $(USER)

plan:
	cd $(TF_DIR) && terraform plan

apply:
	cd $(TF_DIR) && terraform apply

destroy:
	cd $(TF_DIR) && terraform destroy

vms-list:
	$(VIRSH) list --all

vms-stop:
	@for vm in $(VM_NAMES); do \
		$(VIRSH) shutdown $(VM_PREFIX)-$$vm 2>/dev/null || \
		$(VIRSH) destroy $(VM_PREFIX)-$$vm 2>/dev/null || true; \
	done

vms-start:
	@for vm in $(VM_NAMES); do \
		$(VIRSH) start $(VM_PREFIX)-$$vm 2>/dev/null || true; \
	done

ssh-balancer:
	ssh $(SSH_OPTS) $(SSH_USER)@192.168.100.10

ssh-server1:
	ssh $(SSH_OPTS) $(SSH_USER)@192.168.100.11

ssh-server2:
	ssh $(SSH_OPTS) $(SSH_USER)@192.168.100.12

ssh-db:
	ssh $(SSH_OPTS) $(SSH_USER)@192.168.100.13
