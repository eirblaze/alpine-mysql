FROM alpine:3.14 as builder
MAINTAINER WangXian <xian366@126.com>

RUN apk update && apk add tzdata

FROM alpine:3.14

# time zone. check: $ date
COPY --from=builder /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# supervisor
COPY ./conf/supervisord.conf /etc/supervisord.conf

# [DockerでMySQLを起動するDockerfileを書いてみた](https://hidemium.hatenablog.com/entry/2014/05/23/070000)
# ソケット用ディレクトリ: /run/mysqld
RUN mkdir -p /run/mysqld; \
  apk add --update --no-cache \
    mysql \
    mysql-client \
    # supervisor \
  ; \
  # rm -f /var/cache/apk/*; \
  /usr/bin/mysql_install_db \
    --datadir=/app/mysql/ \
    --defaults-file=~/.my.cnf \
    --user=mysql \
    --socket=/run/mysqld/mysqld.sock \
  ;
  # (/usr/bin/mysqld_safe --user=root --console &);

# HEALTHCHECK --interval=5s --timeout=3s CMD mysql --host=127.0.0.1 --silent --execute "SELECT 1;" || exit 1
# HEALTHCHECK --interval=5s --timeout=3s CMD mysqladmin ping -h localhost --silent || exit 1

WORKDIR /app
VOLUME /app
EXPOSE 3306

# mysql config
COPY ./conf/.my.cnf /etc/my.cnf.d/zzz-my.cnf

# These lines moved to the end allow us to rebuild image quickly after only these files were modified.
COPY ./conf/db-init.sh /root/db-init.sh

# ENTRYPOINTはデフォルトでシェル、CMDはその引数でしかない、ってこと？CMDは、docker-compose側の command: でも指定可能。
# Dockerのコンソールにどれが映るかも要検証。
CMD ["/root/db-init.sh"]
# CMD ["supervisord", "-n"]

