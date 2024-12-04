#!/bin/bash

# Количество запросов
num_requests=50

# Инициализация ассоциативного массива для суммирования tps
declare -A total_tps
declare -A count_tps

# Выполняем iostat несколько раз
for ((i = 1; i <= num_requests; i++)); do
    # Получаем вывод команды iostat и извлекаем данные для nvme устройств
    output=$(iostat -d 1 1 | awk '/^nvme/ {print $1, $2}')
    sleep 0.1
    # Читаем значения для каждого nvme устройства
    while read -r device tps; do
        total_tps[$device]=$(echo "${total_tps[$device]:-0} + $tps" | bc)
        count_tps[$device]=$((count_tps[$device] + 1))
    done <<< "$output"
done

# Выводим средние данные для каждого nvme устройства
for device in "${!total_tps[@]}"; do
    average_tps=$(echo "scale=2; ${total_tps[$device]} / $num_requests" | bc)
    echo "$device tps: $average_tps"
done
