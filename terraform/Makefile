VIRSH           := virsh -c qemu:///system
VM_IPS          := 192.168.100.10 192.168.100.11 192.168.100.12 192.168.100.13
VM_DISK_SIZE_GB ?= 12
VM_NAMES        := balancer server1 server2 db
VM_PREFIX       := devops-lab

.PHONY: init plan apply destroy setup-host fmt validate \
	vms-list vms-stop vms-start clean-lab-images destroy-force vm-resize-disks

init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply

destroy: vms-stop
	terraform destroy

setup-host: init
	@grep -q '^dynamic_ownership' /etc/libvirt/qemu.conf 2>/dev/null || \
		echo 'dynamic_ownership = 1' | sudo tee -a /etc/libvirt/qemu.conf
	@sudo sed -i 's/^#\?dynamic_ownership.*/dynamic_ownership = 1/' /etc/libvirt/qemu.conf
	@grep -q '^security_driver' /etc/libvirt/qemu.conf 2>/dev/null || \
		echo 'security_driver = "none"' | sudo tee -a /etc/libvirt/qemu.conf
	@sudo sed -i 's/^#\?security_driver.*/security_driver = "none"/' /etc/libvirt/qemu.conf
	sudo systemctl restart libvirtd
	sudo usermod -aG libvirt $(USER)

fmt:
	terraform fmt

validate:
	terraform validate

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

clean-lab-images:
	@sudo rm -f /var/lib/libvirt/images/devops-lab-*.qcow2 \
		/var/lib/libvirt/images/devops-lab-*.iso
	@sudo rm -rf /var/lib/libvirt/images/devops-lab
	@echo "Lab images removed."

destroy-force: clean-lab-images
	@$(VIRSH) net-destroy devops-lab-net 2>/dev/null || true
	@$(VIRSH) net-undefine devops-lab-net 2>/dev/null || true
	@$(VIRSH) pool-destroy devops-lab 2>/dev/null || true
	@$(VIRSH) pool-undefine devops-lab 2>/dev/null || true
	@$(VIRSH) pool-destroy default 2>/dev/null || true
	@$(VIRSH) pool-undefine default 2>/dev/null || true
	@terraform state list 2>/dev/null | xargs -r -I{} terraform state rm '{}' 2>/dev/null || true
	@echo "Force cleanup done. Run: make apply"

vm-resize-disks:
	@for vm in $(VM_NAMES); do \
		img=/var/lib/libvirt/images/devops-lab/$(VM_PREFIX)-$$vm.qcow2; \
		if [ -f "$$img" ]; then \
			echo "Resizing $$img to $(VM_DISK_SIZE_GB)G..."; \
			sudo qemu-img resize "$$img" $(VM_DISK_SIZE_GB)G; \
		fi; \
	done
	@for ip in $(VM_IPS); do \
		echo "Growing partition on $$ip..."; \
		ssh student@$$ip 'sudo growpart /dev/vda 1 && sudo resize2fs /dev/vda1 && df -h /'; \
	done
