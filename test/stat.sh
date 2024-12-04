#!/bin/bash

# Количество запросов
num_requests=50

# Инициализация ассоциативных массивов для суммирования
declare -A total_tps
declare -A total_kB_read_per_s
declare -A total_kB_wrtn_per_s
declare -A count_tps

# Выполняем iostat несколько раз
for ((i = 1; i <= num_requests; i++)); do
    # Получаем вывод команды iostat и извлекаем данные для nvme устройств
    output=$(iostat -d 1 1 | awk '/^nvme/ {print $1, $2, $3, $4}')
    sleep 0.1
    
    # Читаем значения для каждого nvme устройства
    while read -r device tps kB_read_per_s kB_wrtn_per_s; do
        total_tps[$device]=$(echo "${total_tps[$device]:-0} + $tps" | bc)
        total_kB_read_per_s[$device]=$(echo "${total_kB_read_per_s[$device]:-0} + $kB_read_per_s" | bc)
        total_kB_wrtn_per_s[$device]=$(echo "${total_kB_wrtn_per_s[$device]:-0} + $kB_wrtn_per_s" | bc)
        count_tps[$device]=$((count_tps[$device] + 1))
    done <<< "$output"
done

# Выводим заголовок таблицы
printf "%-15s %-10s %-12s %-12s\n" "Device" "tps" "kB_read/s" "kB_wrtn/s"

# Выводим средние данные для каждого nvme устройства
for device in "${!total_tps[@]}"; do
    average_tps=$(echo "scale=2; ${total_tps[$device]} / ${count_tps[$device]}" | bc)
    average_kB_read_per_s=$(echo "scale=2; ${total_kB_read_per_s[$device]} / ${count_tps[$device]}" | bc)
    average_kB_wrtn_per_s=$(echo "scale=2; ${total_kB_wrtn_per_s[$device]} / ${count_tps[$device]}" | bc)

    printf "%-15s %-10s %-12s %-12s\n" "$device" "$average_tps" "$average_kB_read_per_s" "$average_kB_wrtn_per_s"
done
