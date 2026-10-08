#!/usr/bin/env bash
#
# Доставка статического ресурса на devops-vm
#
# Использование: scripts/deploy.sh [--dry-run]

set -euo pipefail

# === Параметры ===
REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
LOCAL_DIR="$(git rev-parse --show-toplevel)/site/"

# === Разбор аргумента --dry-run ===
DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
elif [[ -n "${1:-}" ]]; then
    echo "Ошибка: неизвестный аргумент '$1'" >&2
    echo "Использование: $0 [--dry-run]" >&2
    exit 1
fi

# === Проверка 4: наличие site/index.html ===
if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "Ошибка: файл ${LOCAL_DIR}index.html не найден" >&2
    exit 1
fi

# === Проверка 5: незафиксированные изменения ===
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Ошибка: в репозитории есть незафиксированные изменения" >&2
    git status --short >&2
    exit 1
fi

# === Проверка сертификата ===
if [[ ! -f "${CA_CERT}" ]]; then
    echo "Ошибка: сертификат ${CA_CERT} не найден" >&2
    echo "Скопируйте его командой: scp devops:/etc/ssl/certs/devops.crt ~/" >&2
    exit 1
fi

# === Доставка через rsync ===
# Требование 8: одно SSH-соединение (rsync -e ssh)
# Требование 9: BatchMode=yes — не спрашивать пароль
echo "==> Доставка ${LOCAL_DIR} -> ${REMOTE}:${REMOTE_DIR}"

rsync -avz --delete \
    --chmod=D755,F644 \
    ${DRY_RUN} \
    -e "ssh -o BatchMode=yes -o ConnectTimeout=5" \
    "${LOCAL_DIR}" \
    "${REMOTE}:${REMOTE_DIR}/"

# === Требование 4: при --dry-run — завершение с кодом 0 без проверки доступности ===
if [[ -n "${DRY_RUN}" ]]; then
    echo "==> Пробный режим завершён"
    exit 0
fi

# === Проверка доступности ресурса (с проверкой сертификата) ===
echo "==> Проверка доступности ${SITE_URL}"
if ! curl -fsS --cacert "${CA_CERT}" -o /dev/null "${SITE_URL}"; then
    echo "Ошибка: ресурс ${SITE_URL} недоступен" >&2
    exit 1
fi

# === Требование 7: вывод короткого хеша ===
SHORT_HASH="$(git rev-parse --short HEAD)"
echo "==> Доставлено успешно. Коммит: ${SHORT_HASH}"
exit 0
