## create and mount partitions
```bash
mkdir -p /mnt/keys
chmod 600 /mnt/keys 
echo "# KEYS to RAMDISK 
tmpfs /mnt/keys tmpfs nodev,nosuid,noexec,nodiratime,size=1M 0 0" | sudo tee -a /etc/fstab
mount /mnt/keys 
ln -sf /mnt/keys ~/keys
```
```bash
lsblk -f # check MOUNTPOINTS
swapon --show # check current SWAP size
```
```bash
fdisk /dev/nvme1n1 #
  # d - delete 
  # n - create
  # w - write changes
```
```bash
DEVICE="/dev/nvme0n1"  # DEVICE="/dev/nvme1n1"
MOUNT_POINT="/mnt/disk1"  # MOUNT_POINT="/mnt/disk2" 
FILE_SYSTEM="xfs"  # FILE_SYSTEM="ext4"
SWAP_SIZE=100 # required SWAP size
```
```bash
sudo mkfs."$FILE_SYSTEM" "${DEVICE}p2"
UUID=$(blkid -s UUID -o value "$DEVICE")
echo "UUID=$UUID $MOUNT_POINT $FILE_SYSTEM defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a
```





```bash
echo "Delete all partitions from $DEVICE..."
sudo umount ${DEVICE}* # Отмонтируем все разделы, если они смонтированы
swapoff ${DEVICE}* # Отмонтируем все свапы на этом диске
sudo parted $DEVICE mklabel gpt  # Создаем новую таблицу разделов GPT

echo "create SWAP=${SWAP_SIZE}G..."
sudo parted -a optimal $DEVICE mkpart primary linux-swap 0% ${SWAP_SIZE}G
SWAP_PART="${DEVICE}p1"  # Пусть это первый раздел
sudo mkswap $SWAP_PART
sudo swapon $SWAP_PART # Активируем SWAP

echo "create $FILE_SYSTEM partition"
sudo parted -a optimal $DEVICE mkpart primary $FILE_SYSTEM ${SWAP_SIZE}G 100%
MAIN_PART="${DEVICE}p2"
sudo mkfs."$FILE_SYSTEM" "$MAIN_PART"

SWAP_UUID=$(sudo blkid -s UUID -o value $SWAP_PART)
echo "UUID=$SWAP_UUID none swap sw,pri=1 0 0" | sudo tee -a /etc/fstab
MAIN_UUID=$(sudo blkid -s UUID -o value $MAIN_PART)
echo "UUID=$MAIN_UUID $MOUNT_POINT $FILE_SYSTEM defaults 0 0" | sudo tee -a /etc/fstab

sudo mkdir -p $MOUNT_POINT
sudo mount -a  # Монтируем все из fstab
```

<details>
<summary>create swapfile1</summary>
	
```bash
echo -e '\n\e[42m create SWAP \e[0m\n'	
fallocate -l ${SWAP_SIZE}G /swapfile1
chmod 600 /swapfile1
mkswap /swapfile1
swapon /swapfile1
echo "/swapfile1 none swap sw,pri=1 0 0" | sudo tee -a /etc/fstab
```

</details>

<details>
<summary>create swapfile2</summary>
	
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

</details>

<details>
<summary>create swap partition</summary>

```bash
mkswap /dev/nvme2n1p2 # format as swap
/dev/disk/by-uuid/<uuid> none swap sw,pri=10 0 0 # add to fstab
# swapoff -a
swapon -a
swapon --show
```

### swap partition script
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