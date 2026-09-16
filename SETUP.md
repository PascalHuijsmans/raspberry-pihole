# Install Raspberry Pi Lite

## Install
- Download Raspberry Pi OS Lite: https://www.raspberrypi.com/software/operating-systems/
- Load the OS on an usb
- Remove SD card
- Make sure boot from usb
- Put SD card back
- Once in install screen 
- Choose keyboard layout
- Boot with for now simple password: 123456
- Connect to internet with ethernet

## Connect SSh
On the device we need to enable ssh.
```bash
sudo systemctl enable --now ssh
```

Then connect to ssh via:
```bash
ssh phuadmin@192.168.1.114
```

## Copy installation from SD Card:
Wipe the current SD card:
```bash
sudo wipefs -a /dev/mmcblk0

sudo sfdisk /dev/mmcblk0 <<'EOF'
label: dos
,512M,c
,,83
EOF

sudo mkfs.vfat -F32 /dev/mmcblk0p1
sudo mkfs.ext4 -F /dev/mmcblk0p2

sudo mkdir -p /mnt/sd
sudo mount /dev/mmcblk0p2 /mnt/sd
sudo mkdir -p /mnt/sd/boot/firmware
sudo mount /dev/mmcblk0p1 /mnt/sd/boot/firmware

sudo rsync -axHAWXS --numeric-ids --info=progress2 / /mnt/sd
sudo rsync -axHAWXS --numeric-ids --info=progress2 /boot/firmware/ /mnt/sd/boot/firmware
```

Now get the base ids and 
```bash
sudo blkid /dev/mmcblk0p1 /dev/mmcblk0p2
```
```
/dev/mmcblk0p1: UUID="21B6-6587" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="83d1afa2-01"
/dev/mmcblk0p2: UUID="ae049ef5-463c-467f-991a-ae2e5739bcd3" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="83d1afa2-02"
```
```bash
BASE=$("83d1afa2")
sudo sed -i "s|PARTUUID=[0-9a-fx]*-01|PARTUUID=${BASE}-01|g; s|PARTUUID=[0-9a-fx]*-02|PARTUUID=${BASE}-02|g" /mnt/sd/etc/fstab
sudo sed -i "s|root=PARTUUID=[0-9a-fx]*-02|root=PARTUUID=${BASE}-02|" /mnt/sd/boot/firmware/cmdline.txt
```

Verify
```bash
grep PARTUUID /mnt/sd/etc/fstab
cat /mnt/sd/boot/firmware/cmdline.txt
```
```
PARTUUID=83d1afa2-01  /boot/firmware  vfat    defaults          0       2
PARTUUID=83d1afa2-02  /               ext4    defaults,noatime  0       1
console=serial0,115200 console=tty1 root=PARTUUID=83d1afa2-02 rootfstype=ext4 fsck.repair=yes rootwait
```

Pull the USB && complete with reboot 
```bash
sudo touch /mnt/sd/boot/firmware/ssh
sudo umount /mnt/sd/boot/firmware /mnt/sd
sudo poweroff
```

# Setup basics
## Run raspberry pi installer
Run raspberry config installer:
- Setup timezone
```bash
sudo raspi-config
```

## Update System
```bash
sudo apt update && sudo apt upgrade -y
```

# Auto update



## Fixed IP
```bash
nmcli con show

sudo nmcli con mod "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 192.168.1.114/24 \
  ipv4.gateway 192.168.1.254 \
  ipv4.dns "1.1.1.1 1.0.0.1" \
  ipv4.ignore-auto-dns yes \
  ipv6.dns "2606:4700:4700::1111" \
  ipv6.ignore-auto-dns yes
&&
sudo nmcli con up "Wired connection 1"

```

## UFW
```bash
sudo apt install -y ufw
```
```bash
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 443 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 80 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 53 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 53 proto udp
sudo ufw deny out from any to 192.0.0.0/8
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw logging off
sudo ufw enable
sudo ufw status verbose
```

## Brute Force Ban
```bash
sudo apt-get install -y fail2ban
sudo systemctl enable --now fail2ban
```

# PiHole

## Install
```bash
curl -sSL https://install.pi-hole.net | bash
```

## Test/Enable

## Custom List
- Make sure you make a PAT in github on this repository, make sure it has the Content (Readonly) permission.
- Add the token to the system and give it the right mod
```bash
sudo -I

cd /etc/pihole/

tee /etc/pihole/blocklist.env >/dev/null <<'EOF'
export PAT=github_pat_....
EOF
chown root:root /etc/pihole/blocklist.env

chmod 600 /etc/pihole/blocklist.env

nano load-custom-blocklist.sh
```
- Then add the contents of the load-customer-blocklist.sh script
- Prepare the folder and make it executable, then test like the cron will do
```bash
mkdir -p /etc/pihole/private-lists

chmod +x load-custom-blocklist.sh

bash -c '. /etc/pihole/blocklist.env && /etc/pihole/load-custom-blocklist.sh'; echo "exit $?"
```
- Then add it to the Pi Hole setup with:
```
file:///etc/pihole/private-lists/blocklist.txt
```
- Last add the cron
```bash
tee /etc/cron.d/pihole-customlist >/dev/null <<'EOF'
*/15 * * * * root . /etc/pihole/blocklist.env && /etc/pihole/load-custom-blocklist.sh >/dev/null 2>&1
EOF

chmod 644 /etc/cron.d/pihole-customlist
```

## Uptime measure


## Fallback
