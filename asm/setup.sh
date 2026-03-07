#!/bin/bash

# Create folder for tool downloads
mkdir -p .setup

# Get bass assembler for Ubuntu
wget https://github.com/ARM9/bass/releases/download/v18/bass-ubuntu.zip -nc -O .setup/bass-ubuntu.zip
unzip -n .setup/bass-ubuntu.zip -d bass-ubuntu
chmod +x bass-ubuntu/bass

# Get OOT Decompressor an N64 crc tool
mkdir -p tools
wget https://github.com/NewLunarFire/OoT_Decompressor/releases/download/sc64/decompressor -O tools/decompressor
wget https://github.com/NewLunarFire/OoT_Decompressor/releases/download/sc64/n64crc -O tools/n64crc
chmod +x tools/*

# Get SC64 deployer
mkdir -p sc64-deployer
wget https://github.com/Polprzewodnikowy/SummerCart64/releases/download/v2.20.2/sc64-deployer-linux-v2.20.2.tar.gz -nc -O .setup/sc64-deployer-linux-v2.20.2.tar.gz
tar -xvf .setup/sc64-deployer-linux-v2.20.2.tar.gz -C sc64-deployer
chmod +x sc64-deployer/sc64deployer

