### Hexlet tests and linter status:
[![Actions Status](https://github.com/programmer-kazarin/devops-for-developers-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/programmer-kazarin/devops-for-developers-project-77/actions)

# Проект: Инфраструктура как код

Локальный стенд на libvirt/KVM: Terraform в `terraform/`, конфигурация в `provider.tf` и `backend.tf`.

## Системные требования

- **ОС:** Ubuntu 22.04 / 24.04 (или другой дистрибутив с KVM и libvirt)
- **CPU:** аппаратная виртуализация (Intel VT-x / AMD-V), проверка: `egrep -c '(vmx|svm)' /proc/cpuinfo` → не `0`
- **RAM:** от 8 GiB на хосте (4 ВМ: 512 MiB + 1 GiB + 1 GiB + 2 GiB + запас под ОС)
- **Диск:** от 15 GiB свободно (4 cloud-образа ~700 MiB каждый + cloud-init ISO)
- **ПО:** [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.0, SSH-ключ `~/.ssh/id_ed25519` (+ `.pub` для cloud-init)
- **Пакеты (Ubuntu/Debian):**

```bash
sudo apt install -y qemu-kvm libvirt-daemon-system virtinst genisoimage
```

`genisoimage` нужен провайдеру libvirt для сборки cloud-init ISO (`mkisofs`).

## Первичная настройка (один раз)

Установите пакеты из раздела выше, затем:

```bash
make setup
```

`make setup` настраивает libvirt (`qemu.conf`), добавляет пользователя в группу `libvirt` и выполняет `terraform init`.

Перелогиньтесь или выполните `newgrp libvirt`, чтобы группа libvirt применилась.

## Terraform

```bash
make plan
make apply
make destroy   # удалить весь стенд (ВМ, сеть, диски)
```

Первый `apply` скачивает cloud-образ для каждой ВМ (~700 MiB × 4), это займёт время.

## Управление ВМ

```bash
make vms-list    # список ВМ (qemu:///system)
make vms-stop    # остановить все (shutdown, иначе destroy)
make vms-start   # запустить остановленные
```

`make destroy` удаляет инфраструктуру через Terraform (не только выключение).  
`make vms-stop` / `make vms-start` — только питание; диски и конфигурация остаются.

## Виртуальные машины

| VM       | IP             | SSH              |
|----------|----------------|------------------|
| balancer | 192.168.100.10 | `make ssh-balancer` |
| server1  | 192.168.100.11 | `make ssh-server1`  |
| server2  | 192.168.100.12 | `make ssh-server2`  |
| db       | 192.168.100.13 | `make ssh-db`         |

Пользователь `student`, вход по ключу `~/.ssh/id_ed25519` (публичный ключ задаётся в `terraform/provider.tf`).

Для Ansible: `ansible_user=student`, тот же приватный ключ.
