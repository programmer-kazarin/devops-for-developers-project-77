### Hexlet tests and linter status:
[![Actions Status](https://github.com/programmer-kazarin/devops-for-developers-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/programmer-kazarin/devops-for-developers-project-77/actions)

# Проект: Инфраструктура как код

## Краткое описание проекта

Лабораторный стенд из четырёх ВМ (KVM/libvirt, Terraform) с развёртыванием приложений через Ansible.

**Стек:** [Wiki.js](https://js.wiki/) (Docker), PostgreSQL 16 (Docker), [Caddy](https://caddyserver.com/) (Docker).

```
Клиент → https://wiki.local (Caddy :443, balancer) → Wiki.js :3000 (webservers) → PostgreSQL (postgres)
```

| VM       | IP             | Ansible (inventory) | SSH                 |
|----------|----------------|---------------------|---------------------|
| balancer | 192.168.100.10 | balancer01          | `make ssh_balanser` |
| server1  | 192.168.100.11 | server1             | `make ssh_server1`  |
| server2  | 192.168.100.12 | server2             | `make ssh_server2`  |
| db       | 192.168.100.13 | postgres01          | `make ssh_postgres` |

Пользователь `student`: первый вход по паролю (`student`, `terraform/variables.tf`), для Ansible — ключ через `ssh-copy-id`.

**Структура репозитория:**

```
├── Makefile              # SSH + делегирование в подкаталоги
├── terraform/            # provider.tf, backend.tf, Makefile
└── ansible/
    ├── Makefile
    ├── inventory.ini
    ├── playbook.yml
    ├── install_postgres.yml
    ├── deploy_wiki.yml
    ├── install_caddy.yml
    ├── group_vars/
    ├── secrets/vault.yml
    └── templates/Caddyfile.j2
```

## Системные требования

- **ОС:** Ubuntu 22.04 / 24.04, KVM/libvirt
- **CPU:** `egrep -c '(vmx|svm)' /proc/cpuinfo` → не `0`
- **RAM:** от 8 GiB
- **Диск:** от 15 GiB свободно на хосте
- **ПО:** Terraform ≥ 1.0, Ansible ≥ 2.14, SSH-ключ `~/.ssh/id_ed25519`

```bash
sudo apt install -y qemu-kvm libvirt-daemon-system virtinst genisoimage ansible
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519   # если ключа ещё нет
ansible-vault --version
```

## Создание инфраструктуры (terraform + ansible)

### Terraform

Один раз настройте хост (libvirt, группа `libvirt`, `terraform init`):

```bash
make setup-host
```

Перелогиньтесь или выполните `newgrp libvirt`.

```bash
make plan
make apply
```

Первый `apply` скачивает cloud-образ один раз (~700 MiB), диски ВМ — COW по 12 GiB (`terraform/provider.tf`). Нужен `make setup-host` (права libvirt на qcow2).

### Ansible (подготовка хостов)

После `apply` дождитесь загрузки ВМ (1–2 мин), затем:

```bash
make install          # Ansible Galaxy (один раз)
make ssh-known-hosts  # опционально: fingerprint в ~/.ssh/known_hosts
make ssh-copy-id      # скопировать ~/.ssh/id_ed25519.pub на все ВМ (пароль student × 4)
make ansible-ping     # pong на всех четырёх хостах
make prepare          # python3-pip + Docker на всех ВМ
```

При ошибке `No space left on device` на старых ВМ: `make vm-resize-disks` или пересоздайте стенд (`make destroy` → `make apply`).

## Секреты

Пароль PostgreSQL хранится в `ansible/secrets/vault.yml` (ansible-vault).

```bash
make vault_edit      # создать / изменить
make vault_view      # просмотр
```

Пример **до** шифрования (`ansible/secrets/vault.yml.example`):

```yaml
---
postgres_password: my_strong_secret_123
```

## Деплой (ansible)

```bash
make deploy_postgres   # спросит пароль vault
make deploy_wiki
make deploy_caddy
```

### Домен
Так как проект запускается локально, добавим 
```192.168.100.10 wiki.local```
в /etc/hosts

### Проверка
```bash
curl -k -I https://wiki.local
# HTTP/2 200
```

Браузер: [https://wiki.local](https://wiki.local). Предупреждение о сертификате можно убрать, установив доверие к `/opt/caddy/data/caddy/pki/ca/root.crt` с балансировщика (`make ssh_balanser`).

## Управление ВМ

```bash
make vms-list     # список ВМ (virsh, qemu:///system)
make vms-stop     # остановить все (shutdown, иначе destroy)
make vms-start    # запустить остановленные
make destroy      # удалить стенд (ВМ, сеть, диски через Terraform)
```

`make vms-stop` / `make vms-start` — только питание; конфигурация и диски сохраняются.

При ошибке destroy `Directory not empty`:

```bash
make clean-lab-images
make destroy
# или
make destroy-force
```
