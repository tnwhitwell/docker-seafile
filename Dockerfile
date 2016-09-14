FROM ubuntu:xenial

ADD https://bintray.com/artifact/download/seafile-org/seafile/seafile-server_6.0.3_x86-64.tar.gz /tmp

RUN tar -xzf /tmp/seafile-server_6.0.3_x86-64.tar.gz -C /tmp && mv /tmp/seafile-server-6.0.3 /seafile

RUN apt-get update && apt-get install -y python && apt-get install -y python2.7 libpython2.7 python-setuptools python-imaging python-ldap python-mysqldb python-memcache python-urllib3

RUN apt-get install -y netcat wget

ADD start.sh /

CMD ["/start.sh"]
