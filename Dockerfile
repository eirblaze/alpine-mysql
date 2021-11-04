FROM alpine:3.14 as builder
MAINTAINER WangXian <xian366@126.com>

RUN apk update && apk add tzdata

FROM alpine:3.14

# time zone. check: $ date
COPY --from=builder /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# mysql config
COPY ./conf/.my.cnf /root/.my.cnf

RUN mkdir -p --ignore-fail-on-non-empty /run/mysqld; \
  apk add --update --no-cache \
    mysql \
    mysql-client \
  ; \
  rm -f /var/cache/apk/*; \
  # [DockerでMySQLを起動するDockerfileを書いてみた](https://hidemium.hatenablog.com/entry/2014/05/23/070000)
  (/usr/bin/mysqld_safe --user=root --console &); \
  sleep 3;

WORKDIR /app
VOLUME /app
EXPOSE 3306

# These lines moved to the end allow us to rebuild image quickly after only these files were modified.
COPY ./conf/db-init.sh /root/db-init.sh

# ENTRYPOINTはデフォルトでシェル、CMDはその引数でしかない、ってこと？CMDは、docker-compose側の command: でも指定可能。
CMD ["/root/db-init.sh"]
