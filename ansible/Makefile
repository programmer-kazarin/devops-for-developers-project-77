export ANSIBLE_CONFIG := $(abspath ansible.cfg)

.PHONY: install setup test prepare deploy_postgres deploy_wiki deploy_caddy deploy_datadog \
	vault_edit vault_view ansible-ping ssh-known-hosts ssh-copy-id inventory-example

inventory-example:
	cp inventory.ini.example inventory.ini

install:
	ansible-galaxy install -r requirements.yml

setup: install

test: setup
ifdef CI
	ansible-playbook -i inventory.ci.ini playbook.yml
else
	ansible-playbook -i inventory.ci.ini playbook.yml --syntax-check
	ansible-playbook -i inventory.ini playbook.yml --syntax-check
	ansible-playbook -i inventory.ini install_caddy.yml --syntax-check
	ansible-playbook -i inventory.ini install_postgres.yml --syntax-check
	ansible-playbook -i inventory.ini deploy_wiki.yml --syntax-check
	ansible-playbook -i inventory.ini install_datadog.yml --syntax-check
endif

prepare:
	ansible-playbook -i inventory.ini playbook.yml

ssh-known-hosts:
	@for ip in 192.168.100.10 192.168.100.11 192.168.100.12 192.168.100.13; do \
		ssh-keyscan -H $$ip 2>/dev/null; \
	done >> $(HOME)/.ssh/known_hosts

# Пароль ВМ: student (terraform variable vm_password). Ключ: ~/.ssh/id_ed25519.pub
ssh-copy-id:
	@test -f $(HOME)/.ssh/id_ed25519.pub || (echo "Создайте ключ: ssh-keygen -t ed25519"; exit 1)
	@echo "Введите пароль student на каждой ВМ (4 раза):"
	ssh-copy-id -o StrictHostKeyChecking=accept-new student@192.168.100.10
	ssh-copy-id -o StrictHostKeyChecking=accept-new student@192.168.100.11
	ssh-copy-id -o StrictHostKeyChecking=accept-new student@192.168.100.12
	ssh-copy-id -o StrictHostKeyChecking=accept-new student@192.168.100.13

ansible-ping:
	ansible all -i inventory.ini -m ping

deploy_caddy:
	ansible-playbook -i inventory.ini install_caddy.yml

deploy_postgres:
	ansible-playbook -i inventory.ini install_postgres.yml --ask-vault-pass

deploy_wiki:
	ansible-playbook -i inventory.ini deploy_wiki.yml --ask-vault-pass --tags deploy

deploy_datadog:
	ansible-playbook -i inventory.ini install_datadog.yml --ask-vault-pass

vault_edit:
	ansible-vault edit secrets/vault.yml

vault_view:
	ansible-vault view secrets/vault.yml
