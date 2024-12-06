#!/bin/bash

 echo "  - iostat.v2 second request -"

# Получаем вывод команды iostat -d для nvme устройств
output=$(iostat -d 1 2 | awk '/^Device/{count++; if (count == 2) {found=1; next}} found && /^nvme/{print $1, $2, $3, $4}')

# Получаем вывод команды iostat -x для %util
util_output=$(iostat -x 1 2 | awk '/^Device/{count++; if (count == 2) {found=1; next}} found && /^nvme/ {print $1, $23}') # $23 соответствует %util

# Выводим заголовок таблицы
printf "%-15s %-10s %-12s %-12s %-12s %-12s\n" "Device" "tps" "kB_read/s" "kB_wrtn/s" "tps*(r+w)" "%util"

# Читаем значения для каждого nvme устройства
while read -r device tps kB_read_per_s kB_wrtn_per_s; do
    # Рассчитываем tps*(r+w)
    tps_rw=$(echo "scale=2; $tps * ($kB_read_per_s + $kB_wrtn_per_s)" | bc)

    # Делим на 100000 и округляем до целого числа
    tps_rw_rounded=$(printf "%.0f" $(echo "$tps_rw / 10000" | bc))

    # Извлекаем %util для текущего устройства
    util=$(echo "$util_output" | awk -v dev="$device" '$1 == dev {print $2}')

    printf "%-15s %-10s %-12s %-12s %-12s %-12s\n" "$device" "$tps" "$kB_read_per_s" "$kB_wrtn_per_s" "$tps_rw_rounded" "$util"
done <<< "$output"
