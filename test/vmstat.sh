#!/bin/bash

echo "=== Memory Statistics for Solana Validator ==="
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo

echo "=== VMSTAT Cache Statistics ==="
# Создаем массив с ключевыми словами для фильтрации vmstat
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

# Функция для форматированного вывода vmstat
print_vmstat_header() {
    printf "%-25s %10s %10s %8s %8s %15s\n" "Cache" "Num" "Total" "Size" "Pages" "Usage %"
    echo "--------------------------------------------------------------------------------"
}

# Получаем все данные vmstat
vmstat_output=$(vmstat -m)

# Печатаем заголовок vmstat
print_vmstat_header

# Обрабатываем каждую строку вывода vmstat
echo "$vmstat_output" | while read line; do
    for pattern in "${patterns[@]}"; do
        if [[ $line =~ ^$pattern ]]; then
            cache=$(echo "$line" | awk '{print $1}')
            num=$(echo "$line" | awk '{print $2}')
            total=$(echo "$line" | awk '{print $3}')
            size=$(echo "$line" | awk '{print $4}')
            pages=$(echo "$line" | awk '{print $5}')
            
            if [ "$total" -ne 0 ]; then
                usage=$(echo "scale=2; $num * 100 / $total" | bc)
            else
                usage="0.00"
            fi
            
            printf "%-25s %10d %10d %8d %8d %14.2f%%\n" "$cache" "$num" "$total" "$size" "$pages" "$usage"
        fi
    done
done

echo -e "\n=== BUDDYINFO Statistics ==="
echo "Free memory chunks by size (order 0-10)"
printf "%-15s %-10s %s\n" "Zone" "Type" "Orders (0-10)"
echo "--------------------------------------------------------------------------------"

# Читаем и обрабатываем buddyinfo
while read -r line; do
    if [[ $line =~ Node[[:space:]]+([0-9]+),[[:space:]]+zone[[:space:]]+([^[:space:]]+)[[:space:]]+(.+) ]]; then
        node="${BASH_REMATCH[1]}"
        zone="${BASH_REMATCH[2]}"
        orders="${BASH_REMATCH[3]}"
        
        # Форматируем вывод только для Normal зоны (наиболее важной для Solana)
        if [[ $zone == "Normal" ]]; then
            printf "%-15s %-10s %s\n" "$zone" "Node $node" "$orders"
        fi
    fi
done < /proc/buddyinfo

echo -e "\n=== PAGETYPEINFO Statistics ==="
echo "Free pages by migration type in Normal zone"
printf "%-15s %-15s %s\n" "Zone" "Type" "Orders (0-10)"
echo "--------------------------------------------------------------------------------"

# Читаем и обрабатываем pagetypeinfo
capture_next=false
while read -r line; do
    if [[ $line =~ "Pages per block:" ]]; then
        continue
    fi
    
    if [[ $line =~ Node[[:space:]]+([0-9]+),[[:space:]]+zone[[:space:]]+Normal,[[:space:]]+type[[:space:]]+([^[:space:]]+)[[:space:]]+(.+) ]]; then
        node="${BASH_REMATCH[1]}"
        type="${BASH_REMATCH[2]}"
        orders="${BASH_REMATCH[3]}"
        
        # Выводим только важные типы страниц
        if [[ $type == "Movable" || $type == "Unmovable" || $type == "Reclaimable" ]]; then
            printf "%-15s %-15s %s\n" "Normal" "$type" "$orders"
        fi
    fi
done < /proc/pagetypeinfo

# Добавляем базовый анализ
echo -e "\n=== Memory Analysis Summary ==="
# Анализ фрагментации из Normal зоны
normal_line=$(grep "Normal" /proc/buddyinfo)
if [[ $normal_line =~ Normal[[:space:]]+([0-9]+[[:space:]]+){11} ]]; then
    large_pages=$(echo $normal_line | awk '{print $13 + $14}')
    echo "Large memory blocks available (orders 9-10): $large_pages"
    
    if [ $large_pages -lt 1000 ]; then
        echo "WARNING: Low number of large memory blocks available!"
    fi
fi

# Анализ Movable страниц
movable_line=$(grep "Normal.*Movable" /proc/pagetypeinfo)
if [[ $movable_line =~ Movable[[:space:]]+([0-9]+[[:space:]]+){11} ]]; then
    echo "Movable pages in Normal zone: $(echo $movable_line | awk '{print $4}')"
fi
