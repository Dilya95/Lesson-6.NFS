# Домашнее задание 6: работа с NFS

## Задания
- запустить 2 виртуальных машины (сервер NFS и клиента);
- на сервере NFS должна быть подготовлена и экспортирована директория; 
- в экспортированной директории должна быть поддиректория с именем upload с правами на запись в неё; 
- экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab — любым способом);
- монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3.


## Структура
- nfss_script.sh — скрипт настройки NFS сервера
- nfsc_script.sh — скрипт настройки клиента
- README.md — описание решения
  


## Выполнение

### Настройка nfs на стороне сервера:
```
root@otus-homework-nfss:~# apt install -y nfs-kernel-server

root@otus-homework-nfss:~# ip a | grep 'eth1'
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    inet 192.168.0.7/24 brd 192.168.0.255 scope global eth1

root@otus-homework-nfss:~# ss -tnplu | grep 2049
tcp   LISTEN 0      64                              0.0.0.0:2049       0.0.0.0:*                                                              
tcp   LISTEN 0      64                                 [::]:2049          [::]:*                                                              
root@otus-homework-nfss:~# ss -tnplu | grep 111
udp   UNCONN 0      0                               0.0.0.0:111        0.0.0.0:*    users:(("rpcbind",pid=2184,fd=5),("systemd",pid=1,fd=130))
udp   UNCONN 0      0                                  [::]:111           [::]:*    users:(("rpcbind",pid=2184,fd=7),("systemd",pid=1,fd=134))
tcp   LISTEN 0      4096                            0.0.0.0:111        0.0.0.0:*    users:(("rpcbind",pid=2184,fd=4),("systemd",pid=1,fd=123))
tcp   LISTEN 0      4096                               [::]:111           [::]:*    users:(("rpcbind",pid=2184,fd=6),("systemd",pid=1,fd=131))

root@otus-homework-nfss:~# mkdir -p /srv/share/upload

root@otus-homework-nfss:~# chown -R nobody:nogroup /srv/share
 
root@otus-homework-nfss:~# chmod 0777 /srv/share/upload
 
root@otus-homework-nfss:~# cat << EOF > /etc/exports 
/srv/share 192.168.0.3/32(rw,sync,root_squash)
EOF

root@otus-homework-nfss:~# exportfs -r
exportfs: /etc/exports [1]: Neither 'subtree_check' or 'no_subtree_check' specified for export "192.168.0.3/32:/srv/share".
  Assuming default behaviour ('no_subtree_check').
  NOTE: this default has changed since nfs-utils version 1.0.x

root@otus-homework-nfss:~# exportfs -s 
/srv/share  192.168.0.3/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)

root@otus-homework-nfss:~# showmount -e 192.168.0.7
Export list for 192.168.0.7:
/srv/share 192.168.0.3/32

```


### Настройка nfs на стороне клиента:
```
root@otus-homework-nfsc:/etc/systemd/network#  apt install nfs-common -y


root@otus-homework-nfsc:/etc/systemd/network# ip a | grep 'eth1'
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    inet 192.168.0.3/24 brd 192.168.0.255 scope global eth1

root@otus-homework-nfsc:~# mkdir -p /mnt


root@otus-homework-nfsc:~# echo "192.168.0.7:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab

root@otus-homework-nfsc:~# systemctl daemon-reload 

root@otus-homework-nfsc:~# systemctl restart remote-fs.target

root@otus-homework-nfsc:/home# cat /etc/fstab
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# / was on /dev/vda3 during curtin installation
/dev/disk/by-uuid/80469199-1ae8-4cef-ac54-5d9bd0adcfc7 / xfs defaults 0 1
# /boot/efi was on /dev/vda2 during curtin installation
/dev/disk/by-uuid/aef83a3e-d677-49bd-80c6-bebbe0aa66c8 /boot/efi ext4 defaults 0 1
192.168.0.7:/srv/share /mnt nfs vers=3,noauto,x-systemd.automount 0 0


root@otus-homework-nfsc:/home# cd /mnt

root@otus-homework-nfsc:/mnt# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=74,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=13140)
192.168.0.7:/srv/share on /mnt type nfs (rw,relatime,vers=3,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.0.7,mountvers=3,mountport=60786,mountproto=udp,local_lock=none,addr=192.168.0.7)
 
```

### Проверка работоспособности:
На стороне сервера
```
root@otus-homework-nfss:~# cd /srv/share/upload

root@otus-homework-nfss:/srv/share/upload# touch check_file

root@otus-homework-nfss:/srv/share/upload# ls -la
total 0
drwxrwxrwx 2 nobody nogroup 43 Apr 23 19:28 .
drwxr-xr-x 3 nobody nogroup 20 Apr 23 19:01 ..
-rw-r--r-- 1 root   root     0 Apr 23 19:28 check_file
```

На стороне клиента
```
root@otus-homework-nfsc:~# cd /mnt/upload

root@otus-homework-nfsc:/mnt/upload# ls -la
total 0
drwxrwxrwx 2 nobody nogroup 43 Apr 23 19:28 .
drwxr-xr-x 3 nobody nogroup 20 Apr 23 19:01 ..
-rw-r--r-- 1 root   root     0 Apr 23 19:28 check_file

root@otus-homework-nfsc:/mnt/upload# touch client_file

root@otus-homework-nfsc:/mnt/upload# ls -la
total 0
drwxrwxrwx 2 nobody nogroup 43 Apr 23 19:28 .
drwxr-xr-x 3 nobody nogroup 20 Apr 23 19:01 ..
-rw-r--r-- 1 root   root     0 Apr 23 19:28 check_file
-rw-r--r-- 1 nobody nogroup  0 Apr 23 19:28 client_file
```


На стороне сервера
```
root@otus-homework-nfss:/srv/share/upload# ls -la
total 0
drwxrwxrwx 2 nobody nogroup 43 Apr 23 19:28 .
drwxr-xr-x 3 nobody nogroup 20 Apr 23 19:01 ..
-rw-r--r-- 1 root   root     0 Apr 23 19:28 check_file
-rw-r--r-- 1 nobody nogroup  0 Apr 23 19:28 client_file
```

На стороне клиента
```
root@otus-homework-nfsc:/mnt/upload# init 6

root@otus-homework-nfsc:~# cd /mnt/upload
root@otus-homework-nfsc:/mnt/upload# ls -la
total 0
drwxrwxrwx 2 nobody nogroup 43 Apr 23 19:28 .
drwxr-xr-x 3 nobody nogroup 20 Apr 23 19:01 ..
-rw-r--r-- 1 root   root     0 Apr 23 19:28 check_file
-rw-r--r-- 1 nobody nogroup  0 Apr 23 19:28 client_file
```

На стороне сервера
```
root@otus-homework-nfss:~# init 6

root@otus-homework-nfss:~# ls -la /srv/share/upload/
total 0
drwxrwxrwx 2 nobody nogroup 43 Apr 23 19:28 .
drwxr-xr-x 3 nobody nogroup 20 Apr 23 19:01 ..
-rw-r--r-- 1 root   root     0 Apr 23 19:28 check_file
-rw-r--r-- 1 nobody nogroup  0 Apr 23 19:28 client_file

root@otus-homework-nfss:~# exportfs -s
/srv/share  192.168.0.3/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)

root@otus-homework-nfss:~# showmount -a 192.168.0.7
All mount points on 192.168.0.7:
192.168.0.3:/srv/share
```

На стороне клиента
```
root@otus-homework-nfsc:/mnt/upload# init 6

root@otus-homework-nfsc:/mnt/upload# showmount -a 192.168.0.7
All mount points on 192.168.0.7:
192.168.0.3:/srv/share

root@otus-homework-nfsc:~# cd /mnt/upload

root@otus-homework-nfsc:/mnt/upload# showmount -a 192.168.0.7
All mount points on 192.168.0.7:
192.168.0.3:/srv/share

root@otus-homework-nfsc:/mnt/upload# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=62,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=3496)
192.168.0.7:/srv/share on /mnt type nfs (rw,relatime,vers=3,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.0.7,mountvers=3,mountport=60786,mountproto=udp,local_lock=none,addr=192.168.0.7)

root@otus-homework-nfsc:/mnt/upload# ls -la
total 0
drwxrwxrwx 2 nobody nogroup 43 Apr 23 19:28 .
drwxr-xr-x 3 nobody nogroup 20 Apr 23 19:01 ..
-rw-r--r-- 1 root   root     0 Apr 23 19:28 check_file
-rw-r--r-- 1 nobody nogroup  0 Apr 23 19:28 client_file

root@otus-homework-nfsc:/mnt/upload# touch final_check

root@otus-homework-nfsc:/mnt/upload# ls -la
total 0
drwxrwxrwx 2 nobody nogroup 62 Apr 23 19:37 .
drwxr-xr-x 3 nobody nogroup 20 Apr 23 19:01 ..
-rw-r--r-- 1 root   root     0 Apr 23 19:28 check_file
-rw-r--r-- 1 nobody nogroup  0 Apr 23 19:28 client_file
-rw-r--r-- 1 nobody nogroup  0 Apr 23 19:37 final_check

```


## Особенности реализации

- Для монтирования используется systemd automount через fstab
- Применены опции:
  - noauto — отключает автоматическое монтирование при загрузке
  - x-systemd.automount — монтирование происходит при первом обращении
- Используется NFSv3 (в соответствии с требованиями задания)
- На сервере включён root_squash для повышения безопасности


## Заметки

- При использовании x-systemd.automount монтирование происходит только при первом обращении к каталогу
- Проверка mount сразу после загрузки может показать, что ресурс не смонтирован
- Для активации необходимо перейти в каталог (cd /mnt)  
