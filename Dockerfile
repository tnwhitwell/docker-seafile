FROM ubuntu:xenial

ADD seafile-pro-server_6.0.0_x86-64.tar.gz /tmp/

RUN mv /tmp/seafile-pro-server-6.0.0 /seafile

RUN apt-get update && apt-get install -y python && apt-get install -y python2.7 libpython2.7 python-setuptools python-imaging python-ldap python-mysqldb python-memcache python-urllib3

RUN apt-get install -y netcat wget

RUN apt-get install -y libreoffice libreoffice-script-provider-python

RUN apt-get install -y poppler-utils && easy_install pip && pip install boto

ADD start.sh /

CMD ["/start.sh"]
