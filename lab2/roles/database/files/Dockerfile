FROM mysql:8.0.31 as build-env

RUN curl \
    https://raw.githubusercontent.com/spring-petclinic/spring-petclinic-rest/master/src/main/resources/db/mysql/initDB.sql \
    | sed '/^GRANT/d' >/docker-entrypoint-initdb.d/1.sql
RUN curl \
    https://raw.githubusercontent.com/spring-petclinic/spring-petclinic-rest/master/src/main/resources/db/mysql/populateDB.sql \
    --output /docker-entrypoint-initdb.d/2.sql

ENV MYSQL_ROOT_PASSWORD='root' \
    MYSQL_ROOT_HOST='%' \
    MYSQL_USER="user" \
    MYSQL_PASSWORD="password" \
    MYSQL_DATABASE="petclinic"
