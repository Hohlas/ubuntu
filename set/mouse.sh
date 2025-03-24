#!/bin/bash

# Обновление списка пакетов и установка необходимых утилит
echo "Установка необходимых пакетов..."
sudo apt update
sudo apt install -y xbindkeys xautomation x11-utils

# Создание или перезапись файла .xbindkeysrc
echo "Создание конфигурационного файла ~/.xbindkeysrc..."
xbindkeys --defaults > ~/.xbindkeysrc

# Добавление команд для кнопок b:8 и b:9 в конец файла .xbindkeysrc
echo "Настройка боковых кнопок мыши..."
cat << 'EOF' >> ~/.xbindkeysrc

# Копировать (Ctrl+Insert) на кнопку 8
"xte 'keydown Control_L' 'key Insert' 'keyup Control_L'"
  b:8

# Вставить (Shift+Insert) на кнопку 9
"xte 'keydown Shift_L' 'key Insert' 'keyup Shift_L'"
  b:9
EOF

# Перезапуск xbindkeys для применения изменений
echo "Перезапуск xbindkeys..."
pkill -f xbindkeys
xbindkeys &

# Создание директории автозагрузки, если её нет
echo "Настройка автозагрузки xbindkeys..."
mkdir -p ~/.config/autostart/

# Создание файла .desktop для автозагрузки xbindkeys
cat > ~/.config/autostart/xbindkeys.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=xbindkeys
Exec=xbindkeys
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Проверка, что xbindkeys запущен
if pgrep -f xbindkeys > /dev/null; then
    echo "xbindkeys успешно запущен. Боковые кнопки настроены:"
    echo "b:8 — Копировать (Ctrl+Insert)"
    echo "b:9 — Вставить (Shift+Insert)"
else
    echo "Ошибка: xbindkeys не запущен. Проверьте конфигурацию."
fi

# Проверка создания файла автозагрузки
if [ -f ~/.config/autostart/xbindkeys.desktop ]; then
    echo "Автозагрузка для xbindkeys успешно настроена. Настройки будут применяться при каждом входе в систему."
else
    echo "Ошибка: не удалось создать файл автозагрузки."
fi

# Указание пользователю проверить кнопки
echo "Проверьте работу боковых кнопок мыши в любом текстовом редакторе."
echo "После перезагрузки системы настройки должны применяться автоматически."
