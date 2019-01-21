## Shadowsocks-libev with simple-obfs installer
This shell help you install shadowsocks listening on port 443.
### Introduction
Install [shadowsocks-libev](https://github.com/shadowsocks/shadowsocks-libev) and [simple-obfs](https://github.com/shadowsocks/simple-obfs).  
Install httpd and get a certificate from [Let’s Encrypt](https://letsencrypt.org) to enable HTTPS on your website.  
You can use shadowsocks via port 443, and also visit your website using HTTPS via 443.  
Maybe it's a good idea to reduce the chance of being banned.  
### Requirement
VPS  
You can sign up through my referral link:  
[Vultr](https://www.vultr.com/?ref=6997378), [DigitalOcean](https://m.do.co/c/7ea2fecf9223), [Linode](https://www.linode.com/?r=69960c4818028406de98ad12d7a19913869992e1), [CloudCone](https://app.cloudcone.com/?ref=1365)  
Domain  
You can register one for free at [freenom](https://my.freenom.com/clientarea.php).  
Point your domain to the IP address with A record.  
### Usage
```bash
wget -O centos7-ss-install.sh https://github.com/M3chD09/shadowsocks-with-obfs-install/raw/master/centos7-ss-install.sh
chmod +x centos7-ss-install.sh
./centos7-ss-install.sh
```
### Notice
Only tested on CentOS 7.  
***Full of bugs.***  
***Need to improve.***
