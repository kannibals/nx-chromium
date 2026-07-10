#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

print_msg() { echo -e "\e[1;32m>>> $1\e[0m"; }
check_err() { if [ "$1" -ne 0 ]; then echo -e "\e[1;31mОшибка: $2\e[0m" >&2; exit 1; fi; }

print_msg "Установка базовых утилит..."
apt update -yq && apt install -yq software-properties-common gnupg wget curl
check_err $? "Не удалось установить базовые утилиты"

# ----Добавление официального репозитория Google Chrome----
print_msg "Настройка официального репозитория Google Chrome..."

# Скачиваем официальный GPG-ключ Google
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg
check_err $? "Не удалось импортировать GPG-ключ Google"

# Добавляем репозиторий в источники APT
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

# ----Установка NoMachine----
print_msg "Установка NoMachine..."
URL="https://web9001.nomachine.com/download/9.7/Linux/nomachine_9.7.3_1_amd64.deb"
FILE="nomachine_9.7.3_1_amd64.deb"

if [ ! -f "$FILE" ]; then
    wget -q -L "$URL" -O "$FILE"
    check_err $? "Не удалось скачать NoMachine"
fi

if [ $(stat -c%s "$FILE") -lt 10000000 ]; then
    rm -f "$FILE"
    check_err 1 "Файл NoMachine слишком мал. Проверьте URL."
fi

apt update -yq
dpkg -i "$FILE"
if [ $? -ne 0 ]; then
    print_msg "Установка недостающих зависимостей для NoMachine..."
    apt install -fyq
    check_err $? "Не удалось исправить зависимости для NoMachine"
fi
rm -f "$FILE"

# ----Установка Openbox и Google Chrome----
print_msg "Установка Openbox и Google Chrome..."
apt install -yq openbox google-chrome-stable
check_err $? "Не удалось установить Openbox или Google Chrome"

# ----Настройка окружения и Автозагрузки Google Chrome----
print_msg "Настройка сессии и автозапуска..."
mkdir -p /root/.config/openbox
echo "openbox-session" > /root/.xsession

# Заменяем chromium на google-chrome-stable с флагами оптимизации
cat << 'EOF' > /root/.config/openbox/autostart
sleep 3
google-chrome-stable --no-sandbox --start-maximized --no-first-run --disable-default-apps --disable-popup-blocking --disable-infobars &>/dev/null &
EOF
chmod +x /root/.config/openbox/autostart

# ----Настройка UFW (Только порт 4000)----
print_msg "Проверка порта 4000 в UFW..."
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    if ! ufw status numbered | grep -q "4000"; then
        echo "Открываем порт 4000..."
        ufw allow 4000/tcp >/dev/null
    else
        echo "Порт 4000 уже открыт."
    fi
else
    echo "UFW не активен или не установлен. Пропускаем."
fi

# ----Финал----
print_msg "Скрипт успешно выполнен!"
print_msg "IP сервера: $(hostname -I | awk '{print $1}')"
