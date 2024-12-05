

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

