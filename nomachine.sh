#!/bin/bash

print_message() {
    echo -e "\e[1;32m$1\e[0m"  # Зелёный цвет для сообщений
}

check_error() {
    if [ $? -ne 0 ]; then
        echo -e "\e[1;31mОшибка: $1\e[0m" >&2
        exit 1
    fi
}

print_message "Шаг 1: Установка Openbox..."
apt update || check_error "Не удалось обновить пакеты"
apt install -y openbox || check_error "Не удалось установить Openbox"

print_message "Шаг 2: Установка nomachine..."
NOMACHINE_URL="https://web9001.nomachine.com/download/9.3/Linux/nomachine_9.3.7_1_amd64.deb"
NOMACHINE_FILE="nomachine_9.3.7_1_amd64.deb"

if [ ! -f "$NOMACHINE_FILE" ]; then
    wget "$NOMACHINE_URL" || check_error "Не удалось скачать nomachine"
fi

dpkg -i "$NOMACHINE_FILE" || check_error "Не удалось установить nomachine"
apt install -fy || check_error "Не удалось исправить зависимости"

[ -f "$NOMACHINE_FILE" ] && rm "$NOMACHINE_FILE"

print_message "Шаг 3: Настройка Openbox для nomachine..."
mkdir -p /root/.config/openbox || check_error "Не удалось создать конфигурационную директорию"
echo "openbox-session" > /root/.xsession || check_error "Не удалось настроить сессию Openbox"

print_message "Шаг 4: Установка сhromium"
snap install chromium || check error "Не удалось установить сhromium"

print_message "Шаг 5: Настройка автозагрузки сhromium..."

{
    echo "sleep 5"
    echo "MOZ_GTK_TITLEBAR_DECORATION=client сhromium &>/dev/null &"
} > /root/.config/openbox/autostart || check_error "Не удалось создать autostart файл"

chmod +x /root/.config/openbox/autostart || check_error "Не удалось сделать autostart исполняемым"

print_massage "Установка терминала apt install lxterminal"
apt install -y lxterminal || check_error "Не удалось установить lxterminal"

print_message "Шаг 6: Перезапуск Openbox..."
openbox --reconfigure || echo -e "\e[1;33mПредупреждение: Не удалось переконфигурировать Openbox\e[0m" >&2

print_message "Шаг 7: Настройка порта 4000 в UFW..."

if ! command -v ufw >/dev/null 2>&1; then
    echo -e "\e[1;33mUFW не установлен. Пропускаем.\e[0m"
else
    
    if ufw status | grep -q "Status: active"; then
        
        if ufw status numbered | grep -q "4000"; then
            echo -e "\e[1;32mПорт 4000 уже открыт в UFW. Пропускаем.\e[0m"
        else
            echo "Открытие порта 4000..."
            ufw allow 4000/tcp || echo "Не удалось открыть порт 4000"
        fi
    else
        echo -e "\e[1;33mUFW установлен, но не активен. Пропускаем.\e[0m"
    fi
fi

print_message "Настройка завершена успешно!"
print_message "IP-адрес сервера: $(hostname -I | awk '{print $1}')"
