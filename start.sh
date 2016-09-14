#!/bin/bash

while ! nc -z $MYSQL_HOST 3306; do sleep 3; done
cd /data
if [ ! -d /data/ccnet ]
then
    rm -rf /conf
    rm -rf /ccnet
    bash /seafile/setup-seafile-mysql.sh auto -d /data/seadata -q $(hostname -i)
    sed -i.bak 's/email = ask_admin_email()/email = os.environ["SEA_ADMIN_USER"]/' /seafile/check_init_admin.py
    sed -i.bak 's/passwd = ask_admin_password()/passwd = os.environ["SEA_ADMIN_PASS"]/' /seafile/check_init_admin.py
    echo "FILE_SERVER_ROOT = http" >> /conf/seahub_settings.py
    mv /conf /data/
    mv /ccnet /data/
fi
ln -s /data/conf /conf
ln -s /data/ccnet /ccnet

echo "Downloading new Caddyserver"
wget -O /tmp/caddy.tar.gz "https://caddyserver.com/download/build?os=linux&arch=amd64&features=cors%2Cfilemanager%2Cgit%2Chugo%2Cipfilter%2Cjwt%2Clocale%2Cmailout%2Cminify%2Cprometheus%2Cratelimit%2Crealip%2Csearch%2Cupload%2Ccloudflare%2Cdigitalocean%2Cdnsimple%2Cdyn%2Cgandi%2Cgooglecloud%2Cnamecheap%2Crfc2136%2Croute53%2Cvultr"
tar --no-same-owner -C /usr/bin/ -xzf /tmp/caddy.tar.gz && rm /tmp/caddy.tar.gz

echo "Regenerating Caddyfile"

echo "$WEB_FQDN {
    #
    # fileserver
    #
    proxy /seafhttp http://127.0.0.1:8082 {
         header_upstream Host {host}
         header_upstream X-Real-IP {remote}
         header_upstream X-Forwarded-For {remote}
         max_fails 0
    }

    #
    # seahub
    #
    fastcgi / 127.0.0.1:8000
}"> /etc/Caddyfile


sed -i "/^SERVICE_URL = /s/= .*/= https:\/\/$WEB_FQDN/" /conf/ccnet.conf
sed -i "/^FILE_SERVER_ROOT = /s/= .*/= 'https:\/\/$WEB_FQDN\/seafhttp'/" /conf/seahub_settings.py

/seafile/seafile.sh start
/seafile/seahub.sh start-fastcgi

caddy --conf /etc/Caddyfile --log stdout
