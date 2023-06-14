FROM ubuntu:22.04

ARG DB_PASSWORD=123456
ARG DB_NAME=mybookmarks
ARG DB_USER=demo

ENV DB_HOST=localhost
ENV DB_PORT=3306
ENV DB_USER=${DB_USER}
ENV DB_NAME=${DB_NAME}
ENV DB_PASSWORD=${DB_PASSWORD}

RUN apt update \
&& apt install -y wget \
&& wget https://npm.taobao.org/mirrors/node/v14.15.0/node-v14.15.0-linux-x64.tar.gz \
&& tar -zxvf node-v14.15.0-linux-x64.tar.gz \
&& ln -s /node-v14.15.0-linux-x64/bin/node /usr/local/bin/node \
&& ln -s /node-v14.15.0-linux-x64/bin/npm /usr/local/bin/npm \
&& apt install -y mysql-server-8.0 \
&& rm node-v14.15.0-linux-x64.tar.gz

RUN mkdir -p /app

COPY src /app/src
COPY view /app/view
COPY package.json /app/package.json
COPY production.js /app/production.js
COPY schema.sql /app/schema.sql

WORKDIR /app

RUN sed -i "s/host: '.*'/host: '${DB_HOST}'/" /app/src/config/adapter.js \
  && sed -i "s/database: '.*'/database: '${DB_NAME}'/" /app/src/config/adapter.js \
  && sed -i "s/port: '.*'/port: '${DB_PORT}'/" /app/src/config/adapter.js \
  && sed -i "s/user: '.*'/user: '${DB_USER}'/" /app/src/config/adapter.js \
  && sed -i "s/password: '.*'/password: '${DB_PASSWORD}'/" /app/src/config/adapter.js \
  && npm install --production \
  && touch /usr/local/bin/start.sh \
  && chmod 777 /usr/local/bin/start.sh \
  && echo "#!/bin/bash" >> /usr/local/bin/start.sh \
  && echo "service mysql start" >> /usr/local/bin/start.sh \
  && echo "mysql -uroot -e \"CREATE USER '${DB_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';\"" >> /usr/local/bin/start.sh \
  && echo "mysql -uroot -e \"GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'localhost';\"" >> /usr/local/bin/start.sh \
  && echo "mysql -uroot -e \"FLUSH PRIVILEGES;\"" >> /usr/local/bin/start.sh \
  && echo "mysql -u${DB_USER} -p'${DB_PASSWORD}' < /app/schema.sql" >> /usr/local/bin/start.sh \
  && echo "node /app/production.js" >> /usr/local/bin/start.sh

EXPOSE  3306
EXPOSE  2000

ENTRYPOINT ["start.sh"]