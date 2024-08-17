## SWAP

```bash
free -h # check current SWAP size
```
```bash
SWAP_SIZE=200 # required SWAP size
```
### swap1
```bash
echo -e '\n\e[42m create SWAP \e[0m\n'	
MIN_DIFFERENCE=1
CURRENT_SWAP_SIZE=$(free -g | awk '/^Swap:/ {print $2}')
ADDITIONAL_SWAP=$((SWAP_SIZE - CURRENT_SWAP_SIZE))
if [ "$ADDITIONAL_SWAP" -gt "$MIN_DIFFERENCE" ]; then
	echo -e " current SWAP size\033[32m ${CURRENT_SWAP_SIZE}G \033[0m"
	echo -e " create additional SWAP\033[32m ${ADDITIONAL_SWAP}G \033[0m"
	command_output=$(fallocate -l ${ADDITIONAL_SWAP}G /swapfile2) 
	command_exit_status=$? #
	if [ $command_exit_status -ne 0 ]; then
		echo -e "\033[31m can't create swapfile2 \033[0m"
	else
		chmod 600 /swapfile2
		mkswap /swapfile2
		swapon /swapfile2
		echo "/swapfile2 none swap sw 0 0" | sudo tee -a /etc/fstab
	fi
else
	echo -e " current SWAP size\033[32m $CURRENT_SWAP_SIZE\033[0m enough "
fi
```
### swap2
```bash
swapoff -a   
dd if=/dev/zero of=/swapfile bs=1G count=$SWAP_SIZE
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
