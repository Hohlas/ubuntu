#!/bin/bash

# Обновляем пакеты и устанавливаем pipx
sudo apt update && sudo apt install pipx

# Устанавливаем ChromaTerm
pipx install chromaterm

# Добавляем ~/.local/bin в PATH
pipx ensurepath

# Создаём конфигурацию ChromaTerm с правилами подсветки
echo "rules:
  - description: IP-address:port RD or RT (e.g., 192.168.1.1:8080 or RT:192.168.1.1:80)
    regex: \b(RT:)?((25[0-5]|(2[0-4]|[0-1]?\d)?\d)\.){3}(25[0-5]|(2[0-4]|[0-1]?\d)?\d):[1-9]\d{0,4}\b
    color: f#00e0d1  # Тёмный бирюзовый
    exclusive: true
  - description: Highlight IP addresses (e.g., 192.168.1.1)
    regex: \b(?:\d{1,3}\.){3}\d{1,3}\b
    color: f#00ffff  # Бирюзовый
    exclusive: true
  - description: Highlight dates (e.g., 2025-03-24)
    regex: \d{4}-\d{2}-\d{2}
    color: f#ffff00  # Жёлтый
    exclusive: true
  - description: Highlight times (e.g., 14:35:12)
    regex: \d{2}:\d{2}:\d{2}
    color: f#ffff00  # Жёлтый
    exclusive: true
  - description: Highlight critical
    regex: (?i)\b(critical|fatal)\b
    color: f#ff00ff  # Пурпурный
  - description: Highlight errors
    regex: (?i)\b(error|failed|exception)\b
    color: f#ff0000  # Красный
  - description: Highlight warnings
    regex: (?i)\b(warn|warning)\b
    color: f#ffa500  # Оранжевый
  - description: Highlight success
    regex: (?i)\b(success|ok|complete)\b
    color: f#00ff00  # Зелёный
  - description: Highlight debug/info
    regex: (?i)\b(debug|info)\b
    color: f#87ceeb  # Голубой
  - description: Highlight numbers (e.g., 12345)
    regex: \b\d+\b
    color: f#800080  # Фиолетовый
" > ~/.chromaterm.yml

# Настраиваем автоматический запуск ChromaTerm в ~/.bashrc
echo '
if [ -f "$HOME/.local/bin/ct" ] && [ -n "$PS1" ] && [ -z "$CHROMATERM_ACTIVE" ]; then
    export CHROMATERM_ACTIVE=1
    exec "$HOME/.local/bin/ct" /bin/bash --login
fi
' >> ~/.bashrc

# Применяем изменения
source ~/.bashrc

# Тестируем
echo "ERROR: Failed at 2025-03-24 14:35:12 on 192.168.1.1 with warning and success 12345"
