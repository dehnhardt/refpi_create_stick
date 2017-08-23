#!/bin/bash
if [ $# -eq 0 ] 
then
	echo "usage ./create_stick /dev/sd...!"
	exit
fi

if [ ! -f $HOME/.mtoolsrc ]
then
    echo "mtools_skip_check=1" > $HOME/.mtoolsrc 
fi

fdisk -l $1

echo "*************************************************"
while true; do
    read -p "Are you sure to create a refpi stick on $1? [y/n] " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer y for yes or n for no.";;
    esac
done

PARTS=$(ls /dev/sdc[1-9]); 
for PART in $PARTS; do umount $PART; done;

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $1
o # clear the in memory partition table
n # new partition
p # primary partition
# partition number 1
# default - start at beginning of disk 
+10M # 10 MB boot parttion
n # new partition
p # primary partition
# partion number 2
# default, start immediately after preceding partition
# default, extend partition to end of disk
# t # change the partition type 
# 2 # partition 2
# c # use fat32
p # print the in-memory partition table
w # write the partition table
q # and we're done
EOF

echo "Create filesystem ext4 on ${1}1"
mkfs.ext4 ${1}1
sudo tune2fs -L Login ${1}1

echo "Create filesysten ext4 on ${1}2"
mkfs.ext4 ${1}2
sudo tune2fs -L Home ${1}2

#mlabel -i ${1}2 ::Home

if [ ! -d /tmp/home ]
then
	mkdir /tmp/home
fi

sleep 1	#mount needs some time before...

mount "${1}2" /tmp/home

if [ ! -d /tmp/login ]
then
	mkdir /tmp/login
fi
mount "${1}1" /tmp/login

mount |grep "$1"

echo "*************************************************"
while true; do
    read -p "What username shoulb be added? " USER
    read -p  "Is $USER correct? [y/n] " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "please retype the username"
		continue;;
        * ) echo "Please answer y for yes or n for no.";;
    esac
done

useradd -b /tmp/home/ -m -g 100 $USER

if [ $? ]
then
	while true; 
	do
		passwd $USER
		if [ $? ]
		then
			break;
		fi
	done
else
	echo "There was an error while creating the user"
fi

umount /tmp/home
umount /tmp/login

