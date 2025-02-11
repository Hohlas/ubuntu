

### iostat
```bash
apt install sysstat -y
curl https://raw.githubusercontent.com/Hohlas/ubuntu/main/test/stat.sh > $HOME/stat.sh
chmod +x $HOME/stat.sh
echo "alias stat='source ~/stat.sh'" >> $HOME/.bashrc
source $HOME/.bashrc
```
```bash
$HOME/stat.sh
```
### memory test
```bash
apt update && apt install python3 python3-pip -y 
pip3 install psutil

mkdir -p ~/memory_test
curl https://raw.githubusercontent.com/Hohlas/ubuntu/main/test/memory_test.py > ~/memory_test/memory_test.py
chmod +x ~/memory_test/memory_test.py 
```
```bash
~/memory_test/memory_test.py
```
```bash
# add to cron
sudo tee <<EOF >/dev/null ~/memtest
~/memory_test/memory_test.py
EOF
chmod +x ~/memtest
mv ~/memtest /etc/cron.hourly/ 
```


[solana setup](https://github.com/Hohlas/solana/tree/main/setup#readme)
