#!/bin/bash

SERVER_IP="$1"
SERVER_PORT=$2
FRONEND_PORT=$3

# Instalation
sudo apt-get update
sudo apt-get upgrade -y
sudo apt autoremove -y
sudo apt-get install curl -y
sudo apt-get install npm -y

cd ~/

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

nvm install 12.11.1


git clone https://github.com/spring-petclinic/spring-petclinic-angular.git

cd spring-petclinic-angular

sed -i "s/localhost/$SERVER_IP/g" src/environments/environment.ts src/environments/environment.prod.ts
sed -i "s/9966/$SERVER_PORT/g" src/environments/environment.ts src/environments/environment.prod.ts


echo N|npm install -g @angular/cli@latest
echo N| npm install 
echo N | ng analytics off

npm install angular-http-server
npm run build -- --prod

npx angular-http-server --path ./dist -p $FRONEND_PORT &

