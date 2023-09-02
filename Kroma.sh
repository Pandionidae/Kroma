#!/bin/bash

if [ ! $KROMA_KEY ]; then
    read -p "Введіть ваш Private key MM: " KROMA_KEY
    echo 'Ваш key MM: ' $KROMA_KEY
fi

sleep 1

source $HOME/.profile
source $HOME/.bash_profile

sudo apt update
sudo apt install mc wget curl git htop netcat net-tools unzip jq build-essential ncdu tmux make cmake clang pkg-config libssl-dev protobuf-compiler -y

ufw disable
git clone https://github.com/kroma-network/kroma-up.git
cd $HOME/kroma-up
git pull origin main
./startup.sh
sleep 1
docker_compose_version=`wget -qO- https://api.github.com/repos/docker/compose/releases/latest | jq -r ".tag_name"`
sudo wget -O /usr/bin/docker-compose "https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m`"
sudo chmod +x /usr/bin/docker-compose
cd $HOME


ip_addr=https://ethereum-sepolia.blockpi.network/v1/rpc/public
sed -i "s|KROMA_NODE__L1_RPC_ENDPOINT=.*|KROMA_NODE__L1_RPC_ENDPOINT=$ip_addr|" $HOME/kroma-up/.env
sed -i "s|KROMA_VALIDATOR__L1_RPC_ENDPOINT=.*|KROMA_VALIDATOR__L1_RPC_ENDPOINT=$ip_addr|" $HOME/kroma-up/.env
sed -i "s|KROMA_VALIDATOR__PRIVATE_KEY=.*|KROMA_VALIDATOR__PRIVATE_KEY=$KROMA_KEY|" $HOME/kroma-up/.env
sed -i 's/--circuitparams.maxtxs = 0 \\/--circuitparams.maxtxs=0 \\/' $HOME/kroma-up/scripts/entrypoint.sh
sed -i '/- kroma-geth/!b;n;/user: root/!a\    user: root' $HOME/kroma-up/docker-compose.yml

source $HOME/kroma-up/.env
cd $HOME/kroma-up/ && docker-compose --profile validator up -d

bash $HOME/kroma-up/sync_block.sh

echo "-----------------------------------------------------------------------------"
echo "Готово!"
echo "-----------------------------------------------------------------------------"
