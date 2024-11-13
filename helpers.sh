# Install script for rng-tools haveged sysstat
# Ubuntu
sudo apt update && sudo apt install rng-tools haveged sysstat -y
# Fedora
sudo dnf install rng-tools haveged sysstat -y

sudo rngd -r /dev/urandom
sudo systemctl start haveged

#check for duplicates -> KEY_LOG_FILE is the file name containing keys
sort $KEY_LOG_FILE | uniq -d > duplicate_keys.txt

#View system logs
tail -f /var/log/syslog  # Ubuntu
tail -f /var/log/messages # Fedora


#Collect Metrics - sysstat
sar -u 1 > performance_metrics.txt
