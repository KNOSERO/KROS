#!/bin/bash

java_version=$1
gradle_version=$2
node_version=$3
npm_version=$4
yarn_version=$5

printf "nameserver 8.8.4.4\nnameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
sudo apt-get  -y update
sudo apt-get  -y upgrade

wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
echo "deb https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ bionic main" | sudo tee /etc/apt/sources.list.d/adoptopenjdk.list
sudo apt update
sudo apt-get install -y $java_version

sudo apt-get install -y zip
sudo apt-get install -y unzip

wget -c https://services.gradle.org/distributions/gradle-${gradle_version}-bin.zip
sudo unzip  gradle-${gradle_version}-bin.zip -d /opt
sudo ln -s /opt/gradle-${gradle_version} /opt/gradle
sudo sh -c "printf 'export GRADLE_HOME=/opt/gradle\nexport PATH=\$PATH:\$GRADLE_HOME/bin\n' > /etc/profile.d/gradle.sh"
source /etc/profile.d/gradle.sh

curl -fsSL https://deb.nodesource.com/setup_${node_version} | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt-get install -y npm
sudo npm install -g yarn