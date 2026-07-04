#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

print_msg() { echo -e "\e[1;32m>>> $1\e[0m"; }
check_err() { if [ "$1" -ne 0 ]; then echo -e "\e[1;31mОшибка: $2\e[0m" >&2; exit 1; fi; }

print_msg "Настройка APT приоритетов..."

rm -f /etc/apt/sources.list.d/debian.list
rm -f /etc/apt/preferences.d/debian-chromium.pref

cat << 'EOF' > /etc/apt/preferences.d/nosnap.pref
Package: chromium-browser*
Pin: release *
Pin-Priority: -1
EOF

cat << 'EOF' > /etc/apt/preferences.d/xtradeb-chromium.pref
Package: chromium chromium-common chromium-sandbox
Pin: release o=LP-PPA-xtradeb-apps
Pin-Priority: 1000
EOF

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

# ----Установка Openbox и Chromium----
print_msg "Установка Openbox и Chromium"
apt install -yq openbox chromium chromium-sandbox
check_err $? "Не удалось установить Openbox или Chromium"

# ----Настройка окружения и Автозагрузки Chromium----
print_msg "Настройка сессии и автозапуска..."
mkdir -p /root/.config/openbox
echo "openbox-session" > /root/.xsession

cat << 'EOF' > /root/.config/openbox/autostart
sleep 3
chromium --no-sandbox --start-maximized --no-first-run --disable-default-apps --disable-popup-blocking --disable-infobars &>/dev/null &
EOF
chmod +x /root/.config/openbox/autostart

# ----Настройка UFW(Только порт 4000)----
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
print_msg "IP сервера: $(hostname -I | awk '{print $1}')"
