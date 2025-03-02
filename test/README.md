

## iostat
<details>
<summary>статистика использования дисков (описание)</summary>

%util (процент утилизации): показывает, насколько загружен диск. 100% означает, что диск постоянно занят. 

rMB/s (скорость чтения): показывает, сколько мегабайт данных считывается с диска в секунду. 

wMB/s (скорость записи): показывает, сколько мегабайт данных записывается на диск в секунду.

</details>

```bash
apt install sysstat -y
curl https://raw.githubusercontent.com/Hohlas/ubuntu/main/test/stat.sh > $HOME/stat.sh
chmod +x $HOME/stat.sh
echo "alias stat='source ~/stat.sh'" >> $HOME/.bashrc
source $HOME/.bashrc
```
```bash
stat 15 # статистика за 15 секунд
```
![image](https://github.com/user-attachments/assets/45261b05-3fb3-4dc1-aff2-953b5d04769b)


## memory test
```bash
apt update && apt install python3 python3-pip -y 
pip3 install psutil

mkdir -p ~/memory_test
curl https://raw.githubusercontent.com/Hohlas/ubuntu/main/test/memory_test.py > ~/memory_test/memory_test.py
curl https://raw.githubusercontent.com/Hohlas/ubuntu/main/test/vmstat.sh > ~/memory_test/vmstat.sh
chmod +x ~/memory_test/memory_test.py ~/memory_test/vmstat.sh
```
```bash
~/memory_test/memory_test.py
~/memory_test/vmstat.sh
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
