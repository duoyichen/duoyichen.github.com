#!/bin/bash
# Author:   DuoyiChen
# Email:    duoyichen@qq.com
# Date:     20190900 00:00
# Modify:   20200904 15:20
# Version:  3

dt0=$(date +%s)
dt1=$(date -d @${dt0} "+%Y%m%d_%H%M%S")
dt2=$(date -d @${dt0} "+%Y-%m-%d %H:%M:%S")
file_name=$(basename $(readlink -f "$0"))
dir_name=$(dirname $(readlink -f "$0"))
#result_path="/root/o/result"
#mkdir -p ${result_path}
#logfile="${result_path}/${file_name}_${dt1}.log"


# Usage1:  curl -sL http://10.10.100.10/o/script/io/test_io.sh|bash
# Usage2:  curl -sL https://duoyichen.github.io/test_io.sh|bash

# exclude system disk,like /dev/*da
dev=$(lsblk -n -d|sort|awk '{print $1}'|egrep -iv "sda|vda"|egrep -i "[s|v]d[a-z]")

# Specified disk,if you want to test /dev/*da,you can chose this option
#dev="sdb sdh"
#dev=$(lsblk -n -d|sort|awk '{print $1}'|egrep -i "[s|v]da")

# No use
#dev=$(lsblk -n -d|sort|awk '{print $1}'|egrep -i "[s|v]d[a-z]")

if [ "${dev}x" == "x" ];then
    echo -e "\033[32mNo device to test!\033[0m"
    exit 2
fi

rpm -qa | grep fio >>/dev/null
if [ "$?" == "0" ];then
    echo -e "\033[32mfio has been installed already! Start testing ...\033[0m"
else
    yum install -y fio
fi

dt3=$(date "+%Y%m%d-%H%M%S")
#base_path=$(hostname -s)_${dt3}
base_path=IO_${dt3}

cd ~

#dev='test_gfs'

for i in ${dev}
do
    echo -e "\n\n\033[32m---------------------------------------- /dev/$i ------------------------------------------------\033[0m\c"
    result_path="${base_path}/$i"
    if [ ! -d ${result_path} ];then
        mkdir -p ${result_path}
    else
        echo "${result_path} is exsit! continue ..."
    fi

    curl -so ${result_path}/$i.conf https://duoyichen.github.io/fio.conf
    #curl -so ${result_path}/$i.conf http://10.10.100.10/o/script/io/fio.conf
    if [ "$i" == "vda" -o "$i" == "sda" ];then
        umount /mnt >> /dev/null 2>&1
        sed -i "/^filename=.*/c filename=\/mnt\/$i" ${result_path}/$i.conf
    else
        sed -i "/^filename=.*/c filename=\/dev\/$i" ${result_path}/$i.conf
        #sed -i "/^filename=.*/c filename=\/var\/vmail\/vmail1\/$i" ${result_path}/$i.conf
    fi

    for j in $(grep "^\[[0-9]\{1,5\}K" ${result_path}/$i.conf | cut -d[ -f2 | cut -d] -f1)
    do
        echo -e "\n\033[36m$j:\033[0m"
        fio ${result_path}/$i.conf --section $j --output ${result_path}/$j.log
    done
done

echo -e "\n\n\033[32mIO test finished! The result:\033[0m\n"
egrep -ri --color "numjobs=|^iodepth=|, bw=|, iops=" ${base_path}
