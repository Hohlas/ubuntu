## create and mount partitions

```bash
echo "# RAMDISK 
tmpfs /mnt/ramdisk tmpfs rw,size=1000G 0 0" | sudo tee -a /etc/fstab
mkdir -p /mnt/ramdisk;
```
```bash
echo "# keys 2 RAM  
tmpfs /mnt/keys tmpfs nodev,nosuid,noexec,nodiratime,size=1M 0 0" | sudo tee -a /etc/fstab
mkdir -p /mnt/keys;
ln -sf /mnt/keys "$HOME/keys"
```
```bash
mkdir -p ~/solana  # ln -sf /mnt/disk2/ledger ~/solana
mkdir -p /mnt/snapshots
mkdir -p /mnt/ramdisk
mount -a
```
```bash
mount | grep tmpfs # show RAM mounted disks
```

<details>
<summary>2 disk config</summary>

```bash
mkdir -p /mnt/disk1/2
mkdir -p /mnt/disk3
ln -sf /mnt/disk1/2 /mnt/disk2
if [ -d "/mnt/ramdisk/accounts_index" ]; then rm -r "/mnt/ramdisk/accounts_index"; fi
ln -sfn /mnt/disk3 /mnt/ramdisk/accounts_index
ln -sfn $HOME/solana/ledger/ /mnt/ramdisk/ledger
```
---
</details>
	
<details>
<summary>3 disk config</summary>

```bash
mkdir -p ~/solana
mkdir -p /mnt/disk1
mkdir -p /mnt/disk2
mkdir -p /mnt/disk3
ln -sfn $HOME/solana/ledger/ /mnt/ramdisk/ledger
```
---
</details>

<details>
<summary>ledger 2 RAM </summary>

```bash
mkdir -p /mnt/ramdisk/ledger
if [ -d "~/solana/ledger" ]; then rm -r "~/solana/ledger"; fi
ln -sfn /mnt/ramdisk/ledger $HOME/solana/ledger
```
---
</details>


```bash
lsblk -f # check MOUNTPOINTS
swapon --show # check current SWAP size
du -h
```
```bash
# create & format partition #
fdisk /dev/nvme0n1
  # d - delete 
  # n - create
  # w - write changes
mkfs.xfs /dev/nvme0n1p1 # mkfs.ext4 /dev/nvme0n1p1
echo "UUID=... /mnt/disk1 xfs defaults 0 0" | sudo tee -a /etc/fstab

mkswap /dev/nvme0n1p2
echo "UUID=... none swap sw,pri=1 0 0" | sudo tee -a /etc/fstab
mount -a
```
### Create SWAP & Partition
```bash
DEVICE="/dev/nvme1n1"; MOUNT_POINT="/mnt/disk1"  #
DEVICE="/dev/nvme0n1"; MOUNT_POINT="/mnt/disk2"  # 
DEVICE="/dev/nvme3n1"; MOUNT_POINT="/mnt/disk3" 
FILE_SYSTEM="xfs" # FILE_SYSTEM="ext4" # 
SWAP_SIZE=100 # required SWAP size
```
```bash
echo "Delete all partitions from $DEVICE..."
umount ${DEVICE}* # Отмонтируем все разделы, если они смонтированы
swapoff -a # Отмонтируем все свапы 
parted --script $DEVICE mklabel gpt  # Создаем новую таблицу разделов GPT

echo "create SWAP=${SWAP_SIZE}G..."
parted -a optimal $DEVICE mkpart primary linux-swap 0% ${SWAP_SIZE}G
SWAP_PART="${DEVICE}p1"  # Пусть это первый раздел
mkswap $SWAP_PART

echo "create $FILE_SYSTEM partition"
parted -a optimal $DEVICE mkpart primary $FILE_SYSTEM ${SWAP_SIZE}G 100%
MAIN_PART="${DEVICE}p2"
mkfs."$FILE_SYSTEM" -f "$MAIN_PART"
#mke2fs -t ext4 -O ^has_journal "$MAIN_PART" # без журналирования

SWAP_UUID=$(sudo blkid -s UUID -o value $SWAP_PART)
MAIN_UUID=$(sudo blkid -s UUID -o value $MAIN_PART)
echo "# "
echo "UUID=$SWAP_UUID none swap sw,pri=1 0 0" | sudo tee -a /etc/fstab
echo "UUID=$MAIN_UUID $MOUNT_POINT $FILE_SYSTEM defaults 0 0" | sudo tee -a /etc/fstab

mkdir -p $MOUNT_POINT
swapon -a # Активируем SWAPы
mount -a  # Монтируем все из fstab
```

<details>
<summary>create swapfile1</summary>
	
```bash
fallocate -l ${SWAP_SIZE}G /swapfile1
chmod 600 /swapfile1
mkswap /swapfile1
printf "\n\n" | sudo tee -a /etc/fstab  # добавление пустых строк
echo "/swapfile1 none swap sw,pri=1 0 0" | sudo tee -a /etc/fstab
swapoff -a
swapon -a
swapon --show
```

</details>

<details>
<summary>create swapfile2</summary>
	
```bash
dd if=/dev/zero of=/swapfile bs=1G count=$SWAP_SIZE
chmod 600 /swapfile #  
mkswap /swapfile     
printf "\n\n" | sudo tee -a /etc/fstab  # добавление пустых строк
echo "/swapfile none swap sw,pri=1 0 0" | sudo tee -a /etc/fstab
swapoff -a 
swapon -a # Активируем SWAPы
swapon --show 
```

</details>

<details>
<summary>create swap partition</summary>

```bash
mkswap /dev/nvme2n1p2 # format as swap
/dev/disk/by-uuid/<uuid> none swap sw,pri=1 0 0 # add to fstab
swapoff -a
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
