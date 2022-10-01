sudo apt install ecryptfs-utils cryptsetup -y
mkdir ~/solana/keys
echo "
#!/bin/bash
sudo mount -t ecryptfs ~/solana/keys ~/solana/keys
" > ~/keys.sh
chmod +x ~/keys.sh
