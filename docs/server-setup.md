# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины
- Объём оперативной памяти: 2048 МБ
- Количество ядер процессора: 2
- Объём дискового накопителя: 25 ГБ (динамически расширяемый, VDI)
- Тип и версия гостевой системы: Ubuntu Server 24.04 LTS (64-bit)
- Расположение VDI: D:\VirtualBox VMs\devops-vm\devops-vm.vdi

## 2. Сетевые интерфейсы
- **Адаптер 1 (NAT):**
  - IP-адрес: 10.0.2.15/24
  - Назначение: доступ в интернет, установка пакетов
- **Адаптер 2 (Host-only):**
  - IP-адрес: 192.168.56.101/24
  - Назначение: управление с хостовой системы, SSH-доступ

## 3. Правило проброса портов
- Порт хостовой системы: 2222
- Порт гостевой системы: 2222
- Протокол: TCP
- Назначение: SSH-доступ к ВМ с хоста

## 4. Учётные записи
- **student:**
  - Группы: student, sudo, users
  - Способ аутентификации: пароль
- **devops:**
  - Группы: devops, sudo, users
  - Способ аутентификации: SSH-ключ (~/.ssh/devops_vm)
  - Используется для администрирования

## 5. Служба SSH
- Порт: 2222
- Файл конфигурации: /etc/ssh/sshd_config.d/99-hardening.conf
- Изменённые директивы:
  - Port 2222
  - PermitRootLogin no
  - PasswordAuthentication no
  - PubkeyAuthentication yes
  - PermitEmptyPasswords no
  - MaxAuthTries 3
  - LoginGraceTime 30
  - AllowUsers devops
  - X11Forwarding no
  - ClientAliveInterval 300
  - ClientAliveCountMax 2

## 6. Правила межсетевого экрана (UFW)
- Политики по умолчанию: deny incoming, allow outgoing
- Правила:
  - 2222/tcp LIMIT (SSH, rate-limited)
  - 80/tcp ALLOW (HTTP)
  - 443/tcp ALLOW (HTTPS)
- Логирование: medium
- Лог-файл: /var/log/ufw.log

## 7. Снимки состояния
- **01-clean-install** — чистая установка Ubuntu Server 24.04 LTS (28.09.2026)
- **02-keys-configured** — ключевая аутентификация настроена (28.09.2026) *(если создавал)*
- **03-ssh-hardened** — SSH hardening завершён (28.09.2026)

## 8. Веб-сервер

### Пакет
- Устанавливаемый пакет: `nginx` (nginx 1.24.0-2ubuntu7.18)
- Служба: `nginx.service` (systemd)

### Конфигурация ресурса
- Путь к конфигурации: `/etc/nginx/sites-available/devops-site`
- Активная ссылка: `/etc/nginx/sites-enabled/devops-site`
- Стандартный ресурс: `/etc/nginx/sites-enabled/default` (удалён)

### Каталог ресурса
- Путь: `/var/www/devops-site`
- Владелец: `devops:devops`
- Права каталога: `755` (`drwxr-xr-x`)
- Права файлов: `644` (`-rw-r--r--`)
- Модель прав: владелец (`devops`) пишет, веб-сервер (`www-data`) читает

### Сертификат и ключ TLS
- Сертификат: `/etc/ssl/certs/devops.crt` (права `644`, владелец `root`)
- Приватный ключ: `/etc/ssl/private/devops.key` (права `600`, владелец `root`)
- Команда формирования сертификата:
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048
-keyout /etc/ssl/private/devops.key
-out /etc/ssl/certs/devops.crt
-subj "/CN=devops.local"
-addext "subjectAltName=DNS:devops.local"
- Срок действия: 365 дней (1 год)
- Тип сертификата: самоподписанный (subject = issuer = CN=devops.local)
- SAN: `DNS:devops.local`

### Служба Nginx
- Процессы: master от `root`, worker от `www-data`
- Порты: 80 (HTTP, перенаправление на HTTPS), 443 (HTTPS)
- Перезагрузка конфигурации: `sudo systemctl reload nginx`

### Логи
- Журнал доступа: `/var/log/nginx/devops-site.access.log`
- Журнал ошибок: `/var/log/nginx/devops-site.error.log`
