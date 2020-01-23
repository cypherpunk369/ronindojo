#!/bin/bash

RED='\033[0;31m'
# used for color with ${RED}
NC='\033[0m'
# No Color

echo -e "${RED}"
echo "***"
echo "Preparing to copy data from your Backup Data Drive now..."
echo "***"
echo -e "${NC}"
sleep 3s

echo -e "${RED}"
echo "Have you mounted the Backup Data Drive?"
echo -e "${NC}"
while true; do
    read -p "Y/N?: " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) bash ~/RoninDojo/Scripts/Menu/dojo-menu2.sh;exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo -e "${RED}"
echo "This will take some time, are you sure that you want to do this?"
echo -e "${NC}"
while true; do
    read -p "Y/N?: " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) bash ~/RoninDojo/Scripts/Menu/dojo-menu2.sh;exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo -e "${RED}"
echo "***"
echo "Making sure Dojo is stopped..."
echo "***"
echo -e "${NC}"
sleep 2s
cd ~/dojo/docker/my-dojo/
sudo ./dojo.sh stop

echo -e "${RED}"
echo "***"
echo "Copying..."
echo "***"
echo -e "${NC}"
sleep 2s

sudo cp -rv /mnt/usb1/chainstate/ /mnt/usb/docker/volumes/my-dojo_data-bitcoind/_data/chainstate/
sudo cp -rv /mnt/usb1/blocks/ /mnt/usb/docker/volumes/my-dojo_data-bitcoind/_data/blocks/
# copy blockchain data from back up drive to dojo bitcoind data directory

sudo chown -R 1105:1108 /mnt/usb/docker/volumes/my-dojo_data-bitcoind/_data/*
# change ownership of blockchain data

echo -e "${RED}"
echo "***"
echo "Complete!"
echo "***"
echo -e "${NC}"
sleep 2s

echo -e "${RED}"
echo "***"
echo "Press any letter to return..."
echo "***"
echo -e "${NC}"
read -n 1 -r -s
bash ~/RoninDojo/Scripts/Menu/dojo-menu2.sh
