#!/bin/bash

while ! nc -z $MYSQL_HOST 3306; do sleep 3; done
sleep 30 #wait for mysql to actually start.
if [ ! -d /data/ccnet ]
then
    mv /seafile /data
    bash /data/seafile/setup-seafile-mysql.sh auto -d /data/seadata -q $(hostname -i)
    sed -i.bak 's/email = ask_admin_email()/email = os.environ["SEA_ADMIN_USER"]/' /data/seafile/check_init_admin.py
    sed -i.bak 's/passwd = ask_admin_password()/passwd = os.environ["SEA_ADMIN_PASS"]/' /data/seafile/check_init_admin.py
    echo "FILE_SERVER_ROOT = http" >> /data/conf/seahub_settings.py
fi

echo "Downloading new Caddyserver"
wget -O /tmp/caddy.tar.gz "https://caddyserver.com/download/build?os=linux&arch=amd64&features=cors%2Cfilemanager%2Cgit%2Chugo%2Cipfilter%2Cjwt%2Clocale%2Cmailout%2Cminify%2Cprometheus%2Cratelimit%2Crealip%2Csearch%2Cupload%2Ccloudflare%2Cdigitalocean%2Cdnsimple%2Cdyn%2Cgandi%2Cgooglecloud%2Cnamecheap%2Crfc2136%2Croute53%2Cvultr"
tar --no-same-owner -C /usr/bin/ -xzf /tmp/caddy.tar.gz && rm /tmp/caddy.tar.gz

echo "Regenerating Caddyfile"

echo "$SERVER_IP {
    #
    # fileserver
    #
    fastcgi / 127.0.0.1:8000
    gzip
    log stdout
    errors stdout
}

$SERVER_IP/media {
    root /data/seafile/seahub/media/
    gzip
    log stdout
    errors stdout
}

$SERVER_IP/seafhttp {
    #
    # seahub
    #
    proxy / 127.0.0.1:8082 {
         header_upstream Host {host}
         header_upstream X-Real-IP {remote}
         header_upstream X-Forwarded-For {remote}
         header_upstream X-Forwarded-Proto {scheme}
         max_fails 0
    }
    rewrite /seafhttp {
        regexp (.*)
        to     {1}
    }
    gzip
    log stdout
    errors stdout
}"> /etc/Caddyfile


sed -i "/^SERVICE_URL = /s/= .*/= https:\/\/$SERVER_IP/" /data/conf/ccnet.conf
sed -i "/^FILE_SERVER_ROOT = /s/= .*/= 'https:\/\/$SERVER_IP\/seafhttp'/" /data/conf/seahub_settings.py

/data/seafile/seafile.sh start
/data/seafile/seahub.sh start-fastcgi

caddy --conf /etc/Caddyfile
