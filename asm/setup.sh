#!/bin/bash

# Create folder for tool downloads
mkdir -p .setup

# Get bass assembler for Ubuntu
wget https://github.com/ARM9/bass/releases/download/v18/bass-ubuntu.zip -nc -O .setup/bass-ubuntu.zip
unzip -n .setup/bass-ubuntu.zip -d bass-ubuntu
chmod +x bass-ubuntu/bass

# Get N64 CRC tool
wget https://dl.smwcentral.net/8799/rn64crc2.zip -nc -O .setup/rn64crc2.zip
unzip -n .setup/rn64crc2.zip -d rn64crc

# Get SC64 deployer
mkdir -p sc64-deployer
wget https://github.com/Polprzewodnikowy/SummerCart64/releases/download/v2.20.2/sc64-deployer-linux-v2.20.2.tar.gz -nc -O .setup/sc64-deployer-linux-v2.20.2.tar.gz
tar -xvf .setup/sc64-deployer-linux-v2.20.2.tar.gz -C sc64-deployer
chmod +x sc64-deployer/sc64deployer