#!/usr/bin/env bash
systemctl stop nginx vapi v2ray

iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT

iptables -F
ip6tables -F

iptables -A INPUT -m ttl --ttl-gt 80 -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A INPUT -p icmp -j ACCEPT
ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

for i in `curl https://www.cloudflare.com/ips-v4`
    do iptables -A INPUT -s $i -p tcp --dport 443 -j ACCEPT
    iptables -A INPUT -s $i -p tcp --dport 80 -j ACCEPT
done
for i in `curl https://www.cloudflare.com/ips-v6`
    do ip6tables -A INPUT -s $i -p tcp --dport 443 -j ACCEPT
    ip6tables -A INPUT -s $i -p tcp --dport 80 -j ACCEPT
done

iptables -P INPUT DROP
ip6tables -P INPUT DROP

apt update
apt install -y iptables-persistent netfilter-persistent
netfilter-persistent save

# nginx
apt install -y nginx
openssl genrsa -out .key 2048
openssl req \
    -subj "/C=HK/ST=Mars/L=Mars/O=Mars/OU=Mars/CN=example.com/emailAddress=user@example.com" \
    -new \
    -key .key \
    -out .csr
openssl x509 \
    -req \
    -days 3650 \
    -in .csr \
    -signkey .key \
    -out .crt

# vapi
curl -L -O https://github.com/vcs6/vapi/releases/download/v0.0.3/vapi-linux-64
chmod 777 vapi-linux-64
cat > /etc/systemd/system/vapi.service << EOF
[Unit]
Description=VAPI Service
After=network.target nss-lookup.target

[Service]
ExecStart=/root/vapi-linux-64
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

# v2ray
curl https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh | bash

systemctl enable vapi v2ray

curl -L -O https://github.com/vcs6/vinit/releases/download/v0.0.4/vinit-linux-64
chmod 777 vinit-linux-64
./vinit-linux-64
rm vinit-linux-64

systemctl restart nginx vapi v2ray
