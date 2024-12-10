#!/bin/bash

# Устанавливаем интервал измерения (по умолчанию 1 секунда)
interval=${1:-1}
echo "  - iostat.v3 second request, measured for $interval sec -"

# Получаем вывод команды iostat -x для %util
util_output=$(iostat -x "$interval" 2 | awk '/^Device/{count++; if (count == 2) {found=1; next}} found && /^nvme/ {print $1, $23, $3, $9}') # $23 соответствует %util, $3 - rkB/s, $9 - wkB/s

# Выводим заголовок таблицы
printf "%-10s %-8s %-8s %-8s\n" "Device" "%util" "rMB/s" "wMB/s"

# Читаем значения для каждого nvme устройства и выводим %util, rkB/s и wkB/s, округляя до целых
while read -r device util rkbs wkbs; do
    # Округляем значение util до целого числа
    util_rounded=$(printf "%.0f" "$util")
    # Округляем rkbs и wkbs до мегабайт
    rkbs_rounded=$(printf "%.0f" "$(echo "$rkbs / 1024" | bc -l)")
    wkbs_rounded=$(printf "%.0f" "$(echo "$wkbs / 1024" | bc -l)")
    printf "%-10s %-8s %-8s %-8s\n" "$device" "$util_rounded" "$rkbs_rounded" "$wkbs_rounded"
done <<< "$util_output"
