#!/bin/bash

# Устанавливаем интервал измерения (по умолчанию 1 секунда)
interval=${1:-1}
echo "  - iostat.v3 second request, measured for $interval sec -"

# Получаем вывод команды iostat -x для %util
util_output=$(iostat -x "$interval" 2 | awk '/^Device/{count++; if (count == 2) {found=1; next}} found && /^nvme/ {print $1, $23}') # $23 соответствует %util

# Выводим заголовок таблицы
printf "%-15s %-12s\n" "Device" "%util"

# Читаем значения для каждого nvme устройства и выводим только %util, округляя до целых
while read -r device util; do
    # Округляем значение util до целого числа
    util_rounded=$(printf "%.0f" "$util")
    printf "%-15s %-12s\n" "$device" "$util_rounded"
done <<< "$util_output"
