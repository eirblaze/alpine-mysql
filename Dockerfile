FROM alpine:3.14 as builder
MAINTAINER WangXian <xian366@126.com>

RUN apk update && apk add tzdata

FROM alpine:3.14

COPY --from=builder /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

WORKDIR /app
VOLUME /app

RUN apk add --update --no-cache \
    mysql \
    mysql-client \
  ; \
  rm -f /var/cache/apk/*; \
  # [DockerでMySQLを起動するDockerfileを書いてみた](https://hidemium.hatenablog.com/entry/2014/05/23/070000)
  (/usr/bin/mysqld_safe &); \
  sleep 3;

# These lines moved to the end allow us to rebuild image quickly after only these files were modified.
COPY ./conf/db-init.sh /root/db-init.sh
COPY ./conf/my.cnf /etc/mysql/my.cnf

EXPOSE 3306

# ENTRYPOINTはデフォルトでシェル、CMDはその引数でしかない、ってこと？CMDは、docker-compose側の command: でも指定可能。
CMD ["/root/db-init.sh"]
