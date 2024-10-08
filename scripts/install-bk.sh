#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

function  error_exit {
  echo "$1" 1>&2
  exit 1
}
trap 'error_exit "Please push issue to: https://github.com/Websoft9/stackhub/issues"' ERR

urls="https://artifact.websoft9.com/release/websoft9"
if [[ "$1" == "dev" ]]; then
    echo "update by dev artifacts"
    urls="https://artifact.websoft9.com/dev/websoft9"
fi

function get_os_type() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
    else
        OS=$(uname -s)
    fi

    if [[ "$OS" == "CentOS Linux" ]]; then
        echo "CentOS"
    elif [[ "$OS" == "CentOS Stream" ]]; then
        echo "CentOS Stream"
    elif [[ "$OS" == "Rocky Linux" ]]; then
        echo "Rocky Linux"
    elif [[ "$OS" == "Oracle Linux Server" ]]; then
        echo "OracleLinux"
    elif [[ "$OS" == "Debian GNU/Linux" ]]; then
        echo "Debian"
    elif [[ "$OS" == "Ubuntu" ]]; then
        echo "Ubuntu"
    elif [[ "$OS" == "Fedora Linux" ]]; then
        echo "Fedora"
    elif [[ "$OS" =~  "Red Hat Enterprise Linux" ]]; then
        echo "Redhat"
    else
        echo $OS
    fi
}

function get_os_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VERSION=$(lsb_release -sr)
    else
        OS=$(uname -s)
        VERSION=$(uname -r)
    fi

    echo $VERSION
}
os_type=$(get_os_type)
os_version=$(get_os_version)

CheckEnvironment(){

echo "---------------------------------- Welcome to install websoft9's appstore, it will take 3-5 minutes -------------------------------------------------------" 

echo "Check  environment ..."
echo  os_type: $os_type
echo  os_version: $os_version
if [ $(id -u) != "0" ]; then
    echo "Please change to root or 'sudo su' to up system privileges, and  reinstall the script again ."
    exit 1
fi

if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ] ; then
    echo "64-bit operating system detected."
else
    echo "This script only works on 64-bit operating systems."
    exit 1
fi

if [ "$os_type" == 'CentOS' ] ;then
  if [ "$os_version" != "7" ]; then
      echo "This app only supported on CentOS 7"
      exit 1
  fi
fi

if  [ "$os_type" == 'CentOS Stream' ] ;then
  if [ "$os_version" != "8" ] || [ "$os_version" != "9" ]; then
      echo "This app only supported on CentOS Stream 8,9"
      exit 1
  fi
fi

if [ "$os_type" == 'Rocky Linux' ] ;then
  if [ "${os_version:0:1}" == "8" ] || [ "${os_version:0:1}" == "9" ]; then
      echo ""
  else
      echo "This app only supported on Rocky Linux 8"
      exit 1
  fi
fi

if  [ "$os_type" == 'Fedora' ];then
  if [ "$os_version" != "37" ]; then
      echo "This app only supported on Fedora 37"
      exit 1
  fi
fi

if  [ "$os_type" == 'Redhat' ];then
  if [ "${os_version:0:1}" != "7" ] && [ "${os_version:0:1}" != "8" ]  && [ "${os_version:0:1}" != "9" ]; then
      echo "This app only supported on Redhat 7,8"
      exit 1
  fi
fi

if  [ "$os_type" == 'Ubuntu' ];then
  if [ "$os_version" != "22.04" ] && [ "$os_version" != "20.04" ] && [ "$os_version" != "18.04" ]; then
      echo "This app only supported on Ubuntu 22.04,20.04,18.04"
      exit 1
  fi
fi

if  [ "$os_type" == 'Debian' ];then
  if [ "$os_version" != "11" ];then
      echo "This app only supported on Debian 11"
      exit 1
  fi
fi

# Check port used
if netstat -tuln | grep -qE ':(80|443|9000)\s'; then
    echo "Port 80,443,9000  is already in use."
    exit 1
else
    echo "Port 80,443, 9000 are free."
fi
          
}

InstallTools(){

echo "Prepare to install Tools ..."

if [ "$os_type" == 'CentOS' ] || [ "$os_type" == 'Rocky Linux' ] || [ "$os_type" == 'CentOS Stream' ]  || [ "$os_type" == 'Fedora' ] || [ "$os_type" == 'OracleLinux' ] || [ "$os_type" == 'Redhat' ];then
  sudo yum update -y
  sudo yum install  git curl wget yum-utils jq bc unzip -y

fi

if [ "$os_type" == 'Ubuntu' ] || [ "$os_type" == 'Debian' ] ;then
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
      echo "Waiting for other software managers to finish..."
      sleep 5
  done
  sudo apt update -y 1>/dev/null 2>&1
  if command -v git > /dev/null;then  
    echo "git installed ..."
  else
    sudo apt install git -y
  fi
  if command -v curl > /dev/null;then  
    echo "jcurlq installed ..."
  else
    sudo apt install curl -y
  fi
  if command -v wget > /dev/null;then  
    echo "wget installed ..."
  else
    sudo apt install wget -y
  fi
  if command -v jq > /dev/null;then  
    echo "jq installed ..."
  else
    sudo apt install jq -y
  fi

  if command -v bc > /dev/null;then  
    echo "bc installed ..."
  else
    sudo apt install bc -y
  fi
  if command -v unzip > /dev/null;then  
    echo "unzip installed ..."
  else
    sudo apt install unzip -y
  fi
fi

}

InstallDocker(){

if command -v docker &> /dev/null
then
    echo "Docker is installed, update..."
    if command -v apt > /dev/null;then  
      sudo apt -y install --only-upgrade  docker-ce docker-ce-cli containerd.io   docker-buildx-plugin docker-compose-plugin
    elif  command -v dnf > /dev/null;then 
      sudo dnf update -y docker-ce docker-ce-cli containerd.io   docker-buildx-plugin docker-compose-plugin
    elif  command -v yum > /dev/null;then 
      sudo yum update -y docker-ce docker-ce-cli containerd.io   docker-buildx-plugin docker-compose-plugin
    fi
    sudo systemctl start docker
    sudo systemctl enable docker
    if ! docker network inspect websoft9 > /dev/null 2>&1; then
      sudo docker network create websoft9
    fi
    return
else
    echo "Docker is not installed, start to install..."
fi
if [ "$os_type" == 'CentOS' ];then
  curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
fi

if [ "$os_type" == 'Ubuntu' ] || [ "$os_type" == 'Debian' ] ;then
  apt-get update
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
      echo "Waiting for other software managers to finish..."
      sleep 5
  done
  curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
  sleep 30
fi

if [ "$os_type" == 'OracleLinux' ] ;then
  sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
fi

if [ "$os_type" == 'Fedora' ] ;then
  wget -O /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/fedora/docker-ce.repo
  sudo yum install device-mapper-persistent-data lvm2 docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-scan-plugin docker-ce-rootless-extras -y
fi

if [ "$os_type" == 'Redhat' ] ;then
  sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc -y 1>/dev/null 2>&1
  sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
fi

if [ "$os_type" == 'CentOS Stream' ] || [ "$os_type" == 'Rocky Linux' ];then
  sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc -y 1>/dev/null 2>&1
  wget -O /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
  sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
fi

sudo systemctl start docker
sudo systemctl enable docker
if ! docker network inspect websoft9 > /dev/null 2>&1; then
  sudo docker network create websoft9
fi

}

InstallCockpit(){
echo "Prepare to install Cockpit ..." 

if [ "${os_type}" == 'Debian' ]; then
  VERSION_CODENAME=$(cat /etc/os-release |grep VERSION_CODENAME|cut -f2 -d"=")
  sudo echo "deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main" >/etc/apt/sources.list.d/backports.list
  sudo apt update
  sudo apt install -t ${VERSION_CODENAME}-backports cockpit -y
  sudo apt install cockpit-pcp cockpit-packagekit -y 1>/dev/null 2>&1
fi

if [ "${os_type}" == 'Ubuntu' ]; then
  if grep -q "^#.*deb http://mirrors.tencentyun.com/ubuntu.*backports" /etc/apt/sources.list; then
      echo "Add backports deb ..." 
      sudo sed -i 's/^#\(.*deb http:\/\/mirrors.tencentyun.com\/ubuntu.*backports.*\)/\1/' /etc/apt/sources.list
      apt update
  fi
  VERSION_CODENAME=$(cat /etc/os-release |grep VERSION_CODENAME|cut -f2 -d"=")
  sudo apt install -t ${VERSION_CODENAME}-backports cockpit -y
  sudo apt install cockpit-pcp -y 1>/dev/null 2>&1
  echo "Cockpit allow root user" 
  echo "" >/etc/cockpit/disallowed-users 1>/dev/null 2>&1
fi

if [ "${os_type}" == 'CentOS' ] || [ "$os_type" == 'OracleLinux' ]; then
  sudo yum install cockpit -y 
  sudo yum install cockpit-pcp cockpit-packagekit -y 1>/dev/null 2>&1
  sudo systemctl enable --now cockpit.socket
  sudo firewall-cmd --permanent --zone=public --add-service=cockpit
  sudo firewall-cmd --reload
fi

if [ "$os_type" == 'Fedora' ]; then
  sudo dnf install cockpit -y 
  sudo dnf install cockpit-pcp cockpit-packagekit -y 1>/dev/null 2>&1
  sudo systemctl enable --now cockpit.socket
  sudo firewall-cmd --add-service=cockpit
  sudo firewall-cmd --add-service=cockpit --permanent
fi

if [ "$os_type" == 'Redhat' ] ; then
  sudo subscription-manager repos --enable rhel-7-server-extras-rpms 1>/dev/null 2>&1
  sudo yum install cockpit -y
  sudo yum install cockpit-pcp cockpit-packagekit -y 1>/dev/null 2>&1
  sudo setenforce 0  1>/dev/null 2>&1
  sudo sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config  1>/dev/null 2>&1
  sudo systemctl enable --now cockpit.socket
  sudo firewall-cmd --add-service=cockpit
  sudo firewall-cmd --add-service=cockpit --permanent
fi

if [ "$os_type" == 'CentOS Stream' ]; then
  sudo subscription-manager repos --enable rhel-7-server-extras-rpms 1>/dev/null 2>&1
  sudo yum install cockpit -y
  sudo yum install cockpit-pcp -y 1>/dev/null 2>&1
  sudo systemctl enable --now cockpit.socket
  sudo firewall-cmd --add-service=cockpit
  sudo firewall-cmd --add-service=cockpit --permanent
  sudo setenforce 0  1>/dev/null 2>&1
  sudo sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config  1>/dev/null 2>&1
  
fi

file="/etc/cockpit/disallowed-users"

if [ -f "$file" ]; then
    echo "" > "$file"
else
    echo "$file is not exist"
fi

echo "Set cockpit port to 9000 ..." 
sudo sed -i 's/ListenStream=9090/ListenStream=9000/' /lib/systemd/system/cockpit.socket


}

InstallPlugins(){

# download apps
mkdir -p /data/apps && cd /data/apps
wget $urls/websoft9-latest.zip
unzip websoft9-latest.zip
cp -r /data/apps/websoft9/docker  /data/apps/w9services
rm -f websoft9-latest.zip

# install plugins
cd /usr/share/cockpit
appstore_version=$(cat /data/apps/websoft9/version.json | jq .PLUGINS |jq .APPSTORE | tr -d '"')
wget $urls/plugin/appstore/appstore-$appstore_version.zip
unzip appstore-$appstore_version.zip

myapps_version=$(cat /data/apps/websoft9/version.json | jq .PLUGINS |jq .MYAPPS| tr -d '"')
wget $urls/plugin/myapps/myapps-$myapps_version.zip
unzip myapps-$myapps_version.zip

portainer_version=$(cat /data/apps/websoft9/version.json | jq .PLUGINS |jq .PORTAINER | tr -d '"')
wget $urls/plugin/portainer/portainer-$portainer_version.zip
unzip portainer-$portainer_version.zip

nginx_version=$(cat /data/apps/websoft9/version.json | jq .PLUGINS |jq .NGINX | tr -d '"')
wget $urls/plugin/nginx/nginx-$nginx_version.zip
unzip nginx-$nginx_version.zip

settings_version=$(cat /data/apps/websoft9/version.json | jq .PLUGINS |jq .SETTINGS | tr -d '"')
wget $urls/plugin/settings/settings-$settings_version.zip
unzip settings-$settings_version.zip

# install navigator
navigator_version=$(cat /data/apps/websoft9/version.json | jq .PLUGINS |jq .NAVIGATOR | tr -d '"')
wget $urls/plugin/navigator/navigator-$navigator_version.zip
unzip navigator-$navigator_version.zip
rm -f *.zip

# install library
cd /data
library_version=$(cat /data/apps/websoft9/version.json | jq .PLUGINS |jq .LIBRARY | tr -d '"')
wget $urls/plugin/library/library-$library_version.zip
unzip library-$library_version.zip
rm -f library-$library_version.zip

# configure cockpit
cp /data/apps/websoft9/cockpit/cockpit.conf /etc/cockpit/cockpit.conf

#####ci-section#####

sudo systemctl daemon-reload
sudo systemctl enable --now cockpit.socket
sudo systemctl restart cockpit.socket

}

StartAppMng(){

echo "Start appmanage API ..." 
cd /data/apps/w9services/w9redis  && sudo docker compose up -d
cd /data/apps/w9services/w9appmanage  && sudo docker compose up -d

public_ip=`bash /data/apps/websoft9/scripts/get_ip.sh`
echo $public_ip > /data/apps/w9services/w9appmanage/public_ip
appmanage_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' websoft9-appmanage)
}

StartPortainer(){

echo "Start Portainer ..." 
cd /data/apps/w9services/w9portainer  && sudo docker compose up -d
docker pull backplane/pwgen
new_password=$(docker run --name pwgen backplane/pwgen 15)!
docker rm -f pwgen
portainer_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' websoft9-portainer)
echo "Portainer init password:" $new_password >> /usr/password.txt
curl -X POST -H "Content-Type: application/json" -d '{"username":"admin", "Password":"'$new_password'"}' http://$portainer_ip:9000/api/users/admin/init
curl "http://$appmanage_ip:5000/AppUpdateUser?user_name=admin&password=$new_password"

}

InstallNginx(){

echo "Install nginxproxymanager ..." 
cd /data/apps/w9services/w9nginxproxymanager && sudo docker compose up -d
sleep 30
echo "edit nginxproxymanager password..." 
nginx_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' websoft9-nginxproxymanager)
login_data=$(curl -X POST -H "Content-Type: application/json" -d '{"identity":"admin@example.com","scope":"user", "secret":"changeme"}' http://$nginx_ip:81/api/tokens)
#token=$(echo $login_data | grep -Po '(?<="token":")[^"]*')
token=$(echo $login_data | jq -r '.token')
while [ -z "$token" ]; do
    sleep 5
    login_data=$(curl -X POST -H "Content-Type: application/json" -d '{"identity":"admin@example.com","scope":"user", "secret":"changeme"}' http://$nginx_ip:81/api/tokens)
    token=$(echo $login_data | jq -r '.token')
done
echo "Nginx token:"$token
new_password=$(docker run --name pwgen backplane/pwgen 15)!
docker rm -f pwgen
echo "Nginx init password:" $new_password >> /usr/password.txt
curl -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $token" -d '{"email": "help@websoft9.com", "nickname": "admin", "is_disabled": false, "roles": ["admin"]}'  http://$nginx_ip:81/api/users/1
curl -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $token" -d '{"type":"password","current":"changeme","secret":"'$new_password'"}'  http://$nginx_ip:81/api/users/1/auth
sleep 3
curl "http://$appmanage_ip:5000/AppUpdateUser?user_name=help@websoft9.com&password=$new_password"
echo "edit password success ..." 
while [ ! -d "/var/lib/docker/volumes/w9nginxproxymanager_nginx_data/_data/nginx/proxy_host" ]; do
    sleep 1
done
cp /data/apps/w9services/w9nginxproxymanager/initproxy.conf /var/lib/docker/volumes/w9nginxproxymanager_nginx_data/_data/nginx/proxy_host
echo $public_ip
sudo sed -i "s/domain.com/$public_ip/g" /var/lib/docker/volumes/w9nginxproxymanager_nginx_data/_data/nginx/proxy_host/initproxy.conf
sudo docker restart websoft9-nginxproxymanager
sudo docker cp websoft9-appmanage:/usr/src/app/db/database.sqlite /usr
}

EditMenu(){

echo "Start to  Edit Cockpit Menu ..."

# uninstall plugins
rm -rf /usr/share/cockpit/apps /usr/share/cockpit/selinux /usr/share/cockpit/kdump /usr/share/cockpit/sosreport /usr/share/cockpit/packagekit
cp -r /data/apps/websoft9/cockpit/menu_override/* /etc/cockpit

echo "---------------------------------- Install success! When installation completed, you can access it by: http://Internet IP:9000 and using Linux user for login to  install a app by websoft9's appstore. -------------------------------------------------------" 
}

CheckEnvironment
InstallTools
InstallDocker
InstallCockpit
InstallPlugins
StartAppMng
StartPortainer
InstallNginx
EditMenu