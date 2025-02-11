#!/bin/bash

# Создаем массив с ключевыми словами для фильтрации
declare -a patterns=(
    "buffer_head"
    "vm_area_struct"
    "filp"
    "shmem_inode_cache"
    "dentry"
    "inode_cache"
    "skbuff_ext_cache"
    "skbuff_head_cache"
    "nf_conntrack"
    "radix_tree_node"
    "vmap_area"
)

# Функция для форматированного вывода
print_header() {
    printf "%-25s %10s %10s %8s %8s %15s\n" "Cache" "Num" "Total" "Size" "Pages" "Usage %"
    echo "--------------------------------------------------------------------------------"
}

# Получаем все данные vmstat
vmstat_output=$(vmstat -m)

# Печатаем заголовок
print_header

# Обрабатываем каждую строку вывода vmstat
echo "$vmstat_output" | while read line; do
    for pattern in "${patterns[@]}"; do
        if [[ $line =~ ^$pattern ]]; then
            # Извлекаем значения с помощью awk
            cache=$(echo "$line" | awk '{print $1}')
            num=$(echo "$line" | awk '{print $2}')
            total=$(echo "$line" | awk '{print $3}')
            size=$(echo "$line" | awk '{print $4}')
            pages=$(echo "$line" | awk '{print $5}')
            
            # Вычисляем процент использования
            if [ "$total" -ne 0 ]; then
                usage=$(echo "scale=2; $num * 100 / $total" | bc)
            else
                usage="0.00"
            fi
            
            # Форматированный вывод
            printf "%-25s %10d %10d %8d %8d %14.2f%%\n" "$cache" "$num" "$total" "$size" "$pages" "$usage"
        fi
    done
done

# Добавляем время запуска для мониторинга
echo -e "\nTimestamp: $(date '+%Y-%m-%d %H:%M:%S')"
