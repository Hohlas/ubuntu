#!/bin/bash

# Количество запросов
num_requests=10

# Инициализация ассоциативных массивов для суммирования
declare -A total_util
declare -A count_util
devices=()  # Массив для хранения имен устройств

# Выполняем iostat несколько раз
for ((i = 1; i <= num_requests; i++)); do
    # Получаем вывод команды iostat -x и извлекаем данные для nvme устройств
    output=$(iostat -x 1 1 | awk '/^nvme/ {print $1, $23}') # $22 соответствует %util
    sleep 1
    
    # Читаем значения для каждого nvme устройства
    while read -r device util; do
        # Сохраняем имя устройства в массиве devices только один раз
        if [[ ! " ${devices[@]} " =~ " ${device} " ]]; then
            devices+=("$device")
        fi
        total_util[$device]=$(echo "${total_util[$device]:-0} + $util" | bc)
        count_util[$device]=$((count_util[$device] + 1))
    done <<< "$output"
done

# Выводим заголовок таблицы
printf "%-15s %-12s\n" "Device" "%util"

# Выводим средние данные для каждого nvme устройства в порядке их появления
for device in "${devices[@]}"; do
    average_util=$(echo "scale=2; ${total_util[$device]} / ${count_util[$device]}" | bc)

    printf "%-15s %-12s\n" "$device" "$average_util"
done
