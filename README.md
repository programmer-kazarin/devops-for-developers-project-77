### Hexlet tests and linter status:
[![Actions Status](https://github.com/programmer-kazarin/devops-for-developers-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/programmer-kazarin/devops-for-developers-project-77/actions)

# Проект: Инфраструктура как код

## Краткое описание проекта

Лабораторный стенд из четырёх ВМ (KVM/libvirt, Terraform) с развёртыванием приложений через Ansible.

**Стек:** [Wiki.js](https://js.wiki/) (Docker), PostgreSQL 16 (Docker), [Caddy](https://caddyserver.com/) (Docker).

```
Клиент → https://wiki.local (Caddy :443, balancer) → Wiki.js :3000 (webservers) → PostgreSQL (postgres)
```

Локальный доступ: добавьте в `/etc/hosts` строку `192.168.100.10 wiki.local`, затем откройте https://wiki.local в браузере.

| VM       | IP             | Ansible (inventory) | SSH                 |
|----------|----------------|---------------------|---------------------|
| balancer | 192.168.100.10 | balancer01          | `make ssh_balanser` |
| server1  | 192.168.100.11 | server1             | `make ssh_server1`  |
| server2  | 192.168.100.12 | server2             | `make ssh_server2`  |
| db       | 192.168.100.13 | postgres01          | `make ssh_postgres` |

Пользователь `student`: первый вход по паролю (`student`, `terraform/variables.tf`), для Ansible — ключ через `ssh-copy-id`.

**Структура репозитория:**

```
├── Makefile
├── terraform/              # инфраструктура libvirt + DataDog monitor
│   ├── provider.tf
│   ├── ansible.tf          # генерация inventory и group_vars для Ansible
│   └── templates/
└── ansible/
    ├── playbook.yml        # главный плейбук
    ├── inventory.ini       # генерируется Terraform (не в git)
    ├── inventory.ini.example
    ├── group_vars/terraform.yml   # генерируется Terraform
    ├── secrets/vault.yml          # ansible-vault
    └── …
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
python3 -m venv venv && source venv/bin/activate   # опционально
```

## Предварительная настройка

| Что | Где | Команда / файл |
|-----|-----|----------------|
| Libvirt + Terraform init | хост | `make setup-host`, затем `newgrp libvirt` |
| VPN для Terraform registry | хост | при ошибке *Content not available in your region* |
| Секреты Ansible | vault | `make vault_edit` → `postgres_password`, `vault_datadog_api_key` |
| Ключи DataDog для Terraform | файл | `cp terraform/terraform.tfvars.example terraform/terraform.tfvars` |
| SSH-ключи на ВМ | — | `make ssh-copy-id` (пароль `student`) |
| Локальный DNS | `/etc/hosts` | `192.168.100.10 wiki.local` |

Пример `ansible/secrets/vault.yml` **до** шифрования (`ansible/secrets/vault.yml.example`):

```yaml
---
postgres_password: "my_strong_secret_123"
vault_datadog_api_key: "YOUR_DATADOG_API_KEY"
```

Пример `terraform/terraform.tfvars` (не коммитить, см. `terraform.tfvars.example`):

```hcl
datadog_api_key = "..."
datadog_app_key = "..."
```

## Полный деплой (порядок команд)

```bash
# 1. Инфраструктура
make setup-host
make init-upgrade          # провайдеры libvirt, local, datadog
make apply                 # ВМ + ansible/inventory.ini + group_vars/terraform.yml

# 2. Ansible
make install
make ssh-copy-id
make ansible-ping
make prepare

# 3. Приложение
make deploy_postgres       # vault password
make deploy_wiki
make deploy_caddy

# 4. DataDog
make deploy_datadog        # vault password
make apply-datadog         # монитор в Terraform

# 5. Проверка
curl -k -I https://wiki.local
make test                  # syntax-check / CI
```

До `make apply` можно подставить пример inventory: `make inventory-example`.

## Создание инфраструктуры (terraform + ansible)

### Terraform

`make apply` создаёт ВМ и **генерирует** для Ansible:

- `ansible/inventory.ini` — из `terraform/templates/inventory.ini.tpl`
- `ansible/group_vars/terraform.yml` — IP и gateway из `local.vms`

```bash
make plan
make apply
make destroy
```

Первый `apply` скачивает cloud-образ (~700 MiB). Диски ВМ — COW 12 GiB. Нужен `make setup-host`.

Если `terraform init` пишет **Invalid provider registry host** — включите **VPN**.

### Ansible (подготовка хостов)

```bash
make install
make ssh-known-hosts       # опционально
make ssh-copy-id
make ansible-ping
make prepare
```

## Секреты

```bash
make vault_edit
make vault_view
```

## Деплой (ansible)

```bash
make deploy_postgres
make deploy_wiki
make deploy_caddy
make deploy_datadog
```

## Мониторинг DataDog

Сайт: **datadoghq.eu**.

| Переменная в проекте | Тип ключа | Где взять | Куда записать |
|----------------------|-----------|-----------|---------------|
| `vault_datadog_api_key` | API Key | [API Keys](https://app.datadoghq.eu/organization-settings/api-keys) | `ansible/secrets/vault.yml` |
| `datadog_api_key` | API Key (тот же) | тот же | `terraform/terraform.tfvars` |
| `datadog_app_key` | Application Key | [Application Keys](https://app.datadoghq.eu/personal-settings/application-keys) | `terraform/terraform.tfvars` |

```bash
make deploy_datadog
make init-upgrade
make apply-datadog
```

**Ошибка `403 Forbidden` при `apply-datadog`:** полные ключи (не KEY ID), не перепутать api/app, для EU: `datadog_api_url = "https://api.datadoghq.eu/"`.

Проверка ключей:

```bash
export DD_API_KEY='...'
export DD_APP_KEY='...'
curl -sS -o /dev/null -w "%{http_code}\n" \
  -H "DD-API-KEY: $DD_API_KEY" -H "DD-APPLICATION-KEY: $DD_APP_KEY" \
  https://api.datadoghq.eu/api/v1/validate
```

В UI: [Hosts](https://app.datadoghq.eu/infrastructure), [Monitors](https://app.datadoghq.eu/monitors/manage).

## Проверка

```bash
# /etc/hosts: 192.168.100.10 wiki.local
curl -k -I https://wiki.local
```

## Makefile

| Каталог | Цели |
|---------|------|
| **корень** | `apply`, `destroy`, `prepare`, `deploy_*`, `deploy_datadog`, `apply-datadog`, `test`, `ssh_server1`, … |
| `terraform/` | `init`, `init-upgrade`, `plan`, `apply`, `destroy`, `vms-list`, `vms-stop`, `vms-start`, `plan-datadog`, `apply-datadog`, `clean-lab-images`, `destroy-force` |
| `ansible/` | `install`, `prepare`, `deploy_*`, `deploy_datadog`, `test`, `vault_edit`, `ansible-ping`, `ssh-copy-id`, `inventory-example` |

| Цель | Назначение |
|------|------------|
| `make test` | Проверка синтаксиса плейбуков (локально и в CI) |
| `make inventory-example` | Скопировать `inventory.ini.example` → `inventory.ini` до `apply` |

## Управление ВМ

```bash
make vms-list
make vms-stop
make vms-start
make destroy
```

При ошибке destroy `Directory not empty`:

```bash
make clean-lab-images
make destroy
# или
make destroy-force
```
