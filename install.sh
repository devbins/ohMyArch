#!/usr/bin/env bash

timedatectl set-ntp true

# 分区
fdisk /dev/sda <<EOF
n
p
1

+512M
n
p
2

+2G
n
p
3

+10G
n
p

+10G
w
EOF

# 格式化
mkfs.vfat -F32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3
mkfs.ext4 /dev/sda4

# 挂载
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir /mnt/home
mount /dev/sda4 /mnt/home

# 更新软件源和安装
pacman -Syy

pacstrap /mnt base linux linux-firmware vim git

genfstab -U /mnt >> /mnt/etc/fstab

# 配置时区，修改 root 密码，创建用户，安装引导
arch-chroot /mnt <<EOFARCH
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/^#zh_CN.UTF-8/zh_CN.UTF-8/' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

cat>>/etc/hosts<<EOF
127.0.0.1	     test
::1	    	test
127.0.1.1	     test.localdomain	   test
EOF

pacman -S --noconfirm dhcp wpa_supplicant dialog networkmanager zsh sudo
systemctl enable NetworkManager

passwd<<EOF
test
test
EOF

useradd -m -G wheel -s /bin/zsh test

passwd test<<EOF
test
test
EOF


pacman -S --noconfirm grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

EOFARCH

echo "Install Complete"
