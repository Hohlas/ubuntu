## SWAP


### swap1
```bash
if [ -e /swapfile ]; then
    SWAP_SIZE=$(swapon --show --noheadings --bytes | awk '{print $3}')
    if [ $SWAP_SIZE -lt $((300 * 1024 * 1024 * 1024)) ]; then
        echo -e '\n\e[42m Увеличение размера SWAP \e[0m\n'
        fallocate -l 300G /swapfile2
        chmod 600 /swapfile2
        mkswap /swapfile2
        swapon /swapfile2
        echo "
# add SWAP
/swapfile2 none swap sw 0 0
" | sudo tee -a /etc/fstab
    else
        echo -e '\n\e[42m SWAP достаточного размера \e[0m\n'
    fi
else
    echo -e '\n\e[42m Создание SWAP \e[0m\n'
    fallocate -l 300G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "
# add SWAP
/swapfile none swap sw 0 0
" | sudo tee -a /etc/fstab
fi
```
### swap2
```bash
swapoff -a   
dd if=/dev/zero of=/swapfile bs=1G count=300
chmod 600 /swapfile #  
mkswap /swapfile
swapon /swapfile       
echo "
# SWAP
/swapfile none swap sw 0 0
" | sudo tee -a /etc/fstab
free -h  
swapon --show 
nano /etc/fstab 
```
### swap partition
```bash
DEVICE="/dev/nvme2n1"
MOUNT_DIR='disk2'
SWAP_SIZE='100'
```
```bash
# Получение общего размера диска в ГБ
TOTAL_SIZE=$(parted -s $DEVICE unit GB print | grep "Disk $DEVICE" | cut -d' ' -f3 | sed 's/GB//')
echo "PARTITION_SIZE=$TOTAL_SIZE"

# Вычисление размера для основного раздела (общий размер минус SWAP_SIZE)
DATA_PARTITION_SIZE=$(echo "$TOTAL_SIZE - $SWAP_SIZE" | bc)
echo "DATA_PARTITION_SIZE=$DATA_PARTITION_SIZE"

echo "Удаление существующей таблицы разделов..."
umount ${DEVICE}p1
wipefs -a $DEVICE

# Создание новых разделов
echo "Создание новых разделов..."
parted -s $DEVICE mklabel gpt
parted -s -a optimal $DEVICE mkpart primary 0% ${DATA_PARTITION_SIZE}GB
parted -s -a optimal $DEVICE mkpart primary ${DATA_PARTITION_SIZE}GB 100%

echo "Форматирование основного раздела как ext4..."
mkfs.ext4 -F ${DEVICE}p1

echo "Форматирование swap раздела..."
mkswap ${DEVICE}p2

echo "Активация swap..."
swapon ${DEVICE}p2

mkdir -p /mnt/$MOUNT_DIR # Создание точки монтирования для основного раздела
mount ${DEVICE}p1 /mnt/$MOUNT_DIR # Монтирование основного раздела

# Добавление записей в /etc/fstab
echo "Добавление записей в /etc/fstab..."
echo "${DEVICE}p1 /mnt/$MOUNT_DIR ext4 defaults 0 2" >> /etc/fstab
echo "${DEVICE}p2 none swap sw 0 0" >> /etc/fstab

echo "Обновление GRUB..."
update-grub

echo "Проверка разделов..."
lsblk $DEVICE
swapon --show
```
