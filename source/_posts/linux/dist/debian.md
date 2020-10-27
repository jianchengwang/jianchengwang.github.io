---
title: Debian
categories: 
- Linux
tags: 
- shell
---

新公司配置的笔记本是 `Win` 系统，因为本人习惯 `Linux` 系统，所以就装了个 `Debian` 子系统玩一下。

最早之前用 `Deepin` 是基于 `Debian` 的，后面用 `Manjaro` 了，忘得差不多了，这里做个记录，方便以后查阅。

<!-- more -->

### 子系统

```shell
# 重启子系统
net stop LxssManager
net start LxssManager

# 进入子系统
bash
```

### set sources.list

```shell
mv /etc/apt/sources.list /etc/apt/sources.list.bak
sudo vim /etc/apt/sources.list

# jessie
deb http://mirrors.163.com/debian/ jessie main non-free contrib
deb http://mirrors.163.com/debian/ jessie-updates main non-free contrib
deb http://mirrors.163.com/debian/ jessie-backports main non-free contrib
deb-src http://mirrors.163.com/debian/ jessie main non-free contrib
deb-src http://mirrors.163.com/debian/ jessie-updates main non-free contrib
deb-src http://mirrors.163.com/debian/ jessie-backports main non-free contrib
deb http://mirrors.163.com/debian-security/ jessie/updates main non-free contrib
deb-src http://mirrors.163.com/debian-security/ jessie/updates main non-free contrib

# squeeze
deb http://mirrors.163.com/debian/ squeeze main non-free contrib
deb http://mirrors.163.com/debian/ squeeze-updates main non-free contrib
deb http://mirrors.163.com/debian/ squeeze-lts main non-free contrib
deb-src http://mirrors.163.com/debian/ squeeze main non-free contrib
deb-src http://mirrors.163.com/debian/ squeeze-updates main non-free contrib
deb-src http://mirrors.163.com/debian/ squeeze-lts main non-free contrib
deb http://mirrors.163.com/debian-security/ squeeze/updates main non-free contrib
deb-src http://mirrors.163.com/debian-security/ squeeze/updates main non-free contrib
deb http://mirrors.163.com/debian-backports/ squeeze-backports main contrib non-free
deb-src http://mirrors.163.com/debian-backports/ squeeze-backports main contrib non-free

# wheezy
deb http://mirrors.163.com/debian/ wheezy main non-free contrib
deb http://mirrors.163.com/debian/ wheezy-updates main non-free contrib
deb http://mirrors.163.com/debian/ wheezy-backports main non-free contrib
deb-src http://mirrors.163.com/debian/ wheezy main non-free contrib
deb-src http://mirrors.163.com/debian/ wheezy-updates main non-free contrib
deb-src http://mirrors.163.com/debian/ wheezy-backports main non-free contrib
deb http://mirrors.163.com/debian-security/ wheezy/updates main non-free contrib
deb-src http://mirrors.163.com/debian-security/ wheezy/updates main non-free contrib

sudo apt-get update
```

### apt-get & dpkg

```shell
apt-get update # update sources
apt-get upgrade # update all installed packages
apt-get dist-upgrade # update system

apt-get install packagename # install

apt-get remove packagename # keep config
apt-get -purge remove packagename # delete config
apt-get autoclean apt # clean deleted backup packages
apt-get clean # clean all backup packages
apt-get autoclean # clean deleted .deb

apt-cache show package

```

### install soft

```shell
# ssh
sudo apt-get install openssh-server
sudo vim /etc/ssh/sshd_config

service ssh start
/etc/init.d/ssh start 

/etc/init.d/ssh status

update-rc.d ssh enable
update-rc.d ssh disabled

# dev tools
sudo apt-get install net-tools
sudo apt-get install curl
sudo apt-get install wget
sudo apt-get install git

sudo apt-get install zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
chsh -s /bin/zsh

sudo apt-get install neovim

# java
wget jdk-8u221-linux-x64.tar.gz
tar -zxvf jdk-8u221-linux-x64.tar.gz
sudo vim /etc/profile
export JAVA_HOME=/home/wjc/lang/jdk1.8.0_221
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
source /etc/profile

# mysql
wget https://dev.mysql.com/get/mysql-apt-config_0.8.13-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.13-1_all.deb 
sudo apt-get update
sudo apt-get install mysql-server
sudo service mysql start
mysql -u root -p
CREATE USER 'wjc'@'%' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON *.* TO 'wjc'@'%';
FLUSH PRIVILEGES;
sudo vim /etc/mysql/mysql.conf.d/mysqlld.cnf
bind-address    = 0.0.0.0

# docker https://docs.docker.com/install/linux/docker-ce/debian/
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
sudo apt-get install docker-ce docker-ce-cli containerd.io

# because wsdl dont't have /etc/fstab,so touch it
sudo touch /etc/fstab
sudo service docker run
# 还是启动不了
sudo dockerd -D
# 错误 Docker doesn't work with iptables v1.8.1
# so config iptables, choose iptables-legacy
sudo update-alternatives --config iptables
# but also failed because According to the Microsoft WSL page on github.com, iptables isn't supported.
# https://stackoverflow.com/questions/50946618/iptables-v1-6-1-cant-initialize-iptables-table-filter-ubuntu-18-04-bash-windo
# so maybe u cant run docker in wsl
sudo docker run hello-world
 
```



