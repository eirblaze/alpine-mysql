#!/bin/sh

# [Docker Compose でMySQLが起動するまで待つ](https://qiita.com/ry0f/items/6e29fa9f689b97058085)
# TIMEOUT_SEC=30
# until mysqladmin ping -h localhost --silent; do
#     echo '[i] waiting for mysqld to be connectable...'
#     sleep 3
# done

if (mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD" ping -h localhost --silent) then
# if [ -d /app/mysql ]; then
  echo "[i] MySQL is alive. skipping setup."
  return 0
fi

echo "[i] MySQL data directory not found, creating initial DBs"

# /usr/bin/mysql_install_db --user=root > /dev/null

/usr/bin/mysql_install_db \
  --datadir=/app/mysql/ \
  --defaults-file=/etc/my.cnf \
  --user=root \
  --socket=/run/mysqld/mysqld.sock \
;

if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
  MYSQL_ROOT_PASSWORD=111111
  echo "[i] MySQL root Password: $MYSQL_ROOT_PASSWORD"
fi

MYSQL_DATABASE=${MYSQL_DATABASE:-""}
MYSQL_USER=${MYSQL_USER:-""}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

tfile=`mktemp`
if [ ! -f "$tfile" ]; then
  echo "[x] mktemp error."
  return 1
fi

cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD" WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
EOF

if [ "$MYSQL_DATABASE" != "" ]; then
  MYSQL_CHARACTER_SET=${MYSQL_CHARACTER_SET:+"CHARACTER SET $MYSQL_CHARACTER_SET"}
  MYSQL_COLLATE=${MYSQL_COLLATE:+"COLLATE $MYSQL_COLLATE"}

  echo "[i] Creating database: $MYSQL_DATABASE"
  echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` $MYSQL_CHARACTER_SET $MYSQL_COLLATE;" >> $tfile

  if [ "$MYSQL_USER" != "" ]; then
    echo "[i] Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
    echo "alter user '$MYSQL_USER'@'localhost' identified by '$MYSQL_PASSWORD';" >> $tfile
    echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
  fi
fi

echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';" >> $tfile

cat $tfile
/usr/bin/mysqld --user=root --bootstrap --verbose=1 < $tfile
# mysql –u username –p new_db_name < dump_file.sql
# mysql --user=root < $tfile
rm -f $tfile

# mysqladmin password "$MYSQL_ROOT_PASSWORD"

exec /usr/bin/mysqld --user=root --console

# -n, --nodaemon	Run supervisord in the foreground.
# exec supervisord -n
