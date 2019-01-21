#!/bin/sh

# Check system
if [ ! -f /etc/redhat-release ];then
    if ! grep -Eqi "centos|red hat|redhat" /etc/issue;then
        echo -e "\033[1;31mOnly CentOS can run this shell.\033[0m"
        exit 1
    fi
fi

# Make sure only root can run our script
[ `whoami` != "root" ] && echo -e "\033[1;31mThis script must be run as root.\033[0m" && exit 1

# Version
LIBSODIUM_VER=1.0.16
MBEDTLS_VER=2.16.0
SHADOWSOCKS_VER=3.2.3

# Set shadowsocks-libev config password
set_password(){
    clear
    echo -e "\033[1;34mPlease enter password for shadowsocks-libev:\033[0m"
    read -p "(Default password: M3chD09):" shadowsockspwd
    [ -z "${shadowsockspwd}" ] && shadowsockspwd="M3chD09"
    echo -e "\033[1;35mpassword = ${shadowsockspwd}\033[0m"
}

# Set domain
set_domain(){
    echo -e "\033[1;34mPlease enter your domain:\033[0m"
    echo "If you don't have one, you can register one for free at:"
    echo "https://my.freenom.com/clientarea.php"
    read domain
    str=`echo $domain | gawk '/^([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/{print $0}'`
    while [ ! -n "${str}" ]
    do
        echo -e "\033[1;31mInvalid domain.\033[0m"
        echo -e "\033[1;31mPlease try again:\033[0m"
        read domain
        str=`echo $domain | gawk '/^([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/{print $0}'`
    done
    echo -e "\033[1;35mdomain = ${domain}\033[0m"
}

# Pre-installation
pre_install(){
    yum install -y epel-release
    yum install -y git wget gettext gcc autoconf libtool automake make asciidoc xmlto c-ares-devel libev-devel zlib-devel openssl-devel rng-tools
}


# Installation of Libsodium
install_libsodium(){
    if [ -f /usr/lib/libsodium.a ];then
        echo -e "\033[1;32mLibsodium already installed, skip.\033[0m"
    else
        if [ ! -f libsodium-$LIBSODIUM_VER.tar.gz ];then
            wget https://download.libsodium.org/libsodium/releases/libsodium-$LIBSODIUM_VER.tar.gz
        fi
        tar xf libsodium-$LIBSODIUM_VER.tar.gz
        pushd libsodium-$LIBSODIUM_VER
        ./configure --prefix=/usr && make
        make install
        popd
        ldconfig
        if [ ! -f /usr/lib/libsodium.a ];then
            clear
            echo -e "\033[1;31mFailed to install libsodium.\033[0m"
            exit 1
        fi
    fi
}


# Installation of MbedTLS
install_mbedtls(){
    if [ -f /usr/lib/libmbedtls.a ];then
        echo -e "\033[1;32mMbedTLS already installed, skip.\033[0m"
    else
        if [ ! -f mbedtls-$MBEDTLS_VER-gpl.tgz ];then
            wget https://tls.mbed.org/download/mbedtls-$MBEDTLS_VER-gpl.tgz
        fi
        tar xf mbedtls-$MBEDTLS_VER-gpl.tgz
        pushd mbedtls-$MBEDTLS_VER
        make SHARED=1 CFLAGS=-fPIC
        make DESTDIR=/usr install
        popd
        ldconfig
        if [ ! -f /usr/lib/libmbedtls.a ];then
            clear
            echo -e "\033[1;31mFailed to install MbedTLS.\033[0m"
            exit 1
        fi
    fi
}


# Installation of shadowsocks-libev
install_ss(){
    if [ -f /usr/local/bin/ss-server ];then
        echo -e "\033[1;32mShadowsocks-libev already installed, skip.\033[0m"
    else
        if [ ! -f shadowsocks-libev-$SHADOWSOCKS_VER.tar.gz ];then
            wget https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$SHADOWSOCKS_VER/shadowsocks-libev-$SHADOWSOCKS_VER.tar.gz
        fi
        tar xf shadowsocks-libev-$SHADOWSOCKS_VER.tar.gz
        pushd shadowsocks-libev-$SHADOWSOCKS_VER
        ./configure && make
        make install
        popd
        if [ ! -f /usr/local/bin/ss-server ];then
            clear
            echo -e "\033[1;31mFailed to install shadowsocks-libev.\033[0m"
            exit 1
        fi
    fi
}

# Installation of simple-obfs
install_obfs(){
    if [ -f /usr/local/bin/obfs-server ];then
        echo -e "\033[1;32mSimple-obfs already installed, skip.\033[0m"
    else
        if [ ! -d simple-obfs ];then
            git clone https://github.com/shadowsocks/simple-obfs.git
        fi
        pushd simple-obfs
        git submodule update --init --recursive
        ./autogen.sh
        ./configure && make
        make install
        popd
        if [ ! -f /usr/local/bin/obfs-server ];then
            clear
            echo -e "\033[1;31mFailed to install simple-obfs.\033[0m" 
            exit 1
        fi
    fi
}

# Configure
ss_conf(){
    mkdir /etc/shadowsocks-libev
    cat >/etc/shadowsocks-libev/config.json << EOF
{
    "server":["[::0]","0.0.0.0"],
    "server_port":443,
    "local_port":1080,
    "password":"$shadowsockspwd",
    "timeout":300,
    "method":"aes-256-gcm",
    "plugin": "obfs-server",
    "plugin_opts": "obfs=tls;obfs-host=www.icloud.com;failover=0.0.0.0:8443"
}
EOF
    cat >/etc/systemd/system/shadowsocks.service << EOF
[Unit]
Description=Shadowsocks
[Service]
TimeoutStartSec=0
ExecStart=/usr/local/bin/ss-server -c /etc/shadowsocks-libev/config.json
[Install]
WantedBy=multi-user.target
EOF
}

create_cert(){
    yum install httpd firewalld -y
    mkdir -p /var/www/home
    cat > /var/www/home/index.html << EOF
<h1>Hello World</h1>
EOF
    cat > /etc/httpd/conf.d/home.conf << EOF
<VirtualHost *:80>
    ServerName $domain
    DocumentRoot /var/www/home/
    <Directory /var/www/home/>
        AllowOverride All
    </Directory>
</VirtualHost>
EOF
    systemctl start httpd
    systemctl enable httpd
    systemctl start firewalld
    systemctl enable firewalld
    firewall-cmd --permanent --zone=public --add-service=http
    firewall-cmd --permanent --zone=public --add-port=443/tcp
    firewall-cmd --permanent --zone=public --add-port=443/udp
    firewall-cmd --reload
    if [ -f /etc/httpd/conf.d/home-le-ssl.conf ];then
        echo -e "\033[1;32mCertificate already created, skip.\033[0m"
    else
        if [ ! -f certbot-auto ];then
            wget https://dl.eff.org/certbot-auto
        fi
        chmod +x certbot-auto
        yum install -y augeas-libs libffi-devel mod_ssl python-devel python-tools python-virtualenv python2-pip redhat-rpm-config gcc openssl openssl-devel ca-certificates
        clear
        echo "We will get a certificate from Let’s Encrypt."
        read -p "Press any key to use certbot." a
        ./certbot-auto << EOF
i@m3chd09.tk
a
n

1
EOF
        if [ ! -f /etc/httpd/conf.d/home-le-ssl.conf ];then
            clear
            echo -e "\033[1;31mFailed to get a certificate.\033[0m"
            exit 1
        fi
    fi
    sed -i 's/:443/:8443/' /etc/httpd/conf.d/home-le-ssl.conf
    sed -i '5s/\<443\>/8443/' /etc/httpd/conf.d/ssl.conf
    sed -i '/^<IfModule mod_ssl.c>/,$d' /etc/httpd/conf/httpd.conf
    systemctl reload httpd
}

start_ss(){
    systemctl enable shadowsocks
    systemctl start shadowsocks
}

remove_files(){
    rm -f libsodium-$LIBSODIUM_VER.tar.gz mbedtls-$MBEDTLS_VER-gpl.tgz shadowsocks-libev-$SHADOWSOCKS_VER.tar.gz
    rm -rf libsodium-$LIBSODIUM_VER mbedtls-$MBEDTLS_VER shadowsocks-libev-$SHADOWSOCKS_VER simple-obfs
}

get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}

print_ss_info(){
    clear
    echo -e "\033[1;32mCongratulations, Shadowsocks-libev server install completed\033[0m"
    echo "Your Server IP        :  $(get_ip) "
    echo "Your Server Port      :  443 "
    echo "Your Password         :  ${shadowsockspwd} "
    echo "Your Encryption Method:  aes-256-gcm "
    echo "Your Plugin           :  obfs-local"
    echo "Your Plugin options   :  obfs=tls;obfs-host=www.icloud.com"
    echo "Enjoy it!"
}
set_password
set_domain
pre_install
install_libsodium
install_mbedtls
install_ss
install_obfs
ss_conf
create_cert
start_ss
remove_files
print_ss_info