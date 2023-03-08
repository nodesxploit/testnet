#
# // Copyright (C) NodeX Capital
#

echo -e "\033[0;35m"
echo " ███╗   ██╗ ██████╗ ██████╗ ███████╗██╗  ██╗     ██████╗ █████╗ ██████╗ ██╗████████╗ █████╗ ██╗     ";
echo " ████╗  ██║██╔═══██╗██╔══██╗██╔════╝╚██╗██╔╝    ██╔════╝██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗██║     ";
echo " ██╔██╗ ██║██║   ██║██║  ██║█████╗   ╚███╔╝     ██║     ███████║██████╔╝██║   ██║   ███████║██║     ";
echo " ██║╚██╗██║██║   ██║██║  ██║██╔══╝   ██╔██╗     ██║     ██╔══██║██╔═══╝ ██║   ██║   ██╔══██║██║     ";
echo " ██║ ╚████║╚██████╔╝██████╔╝███████╗██╔╝ ██╗    ╚██████╗██║  ██║██║     ██║   ██║   ██║  ██║███████╗";
echo " ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝     ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝";
echo ">>> Price Feeder Automatic Installer for Ojo Networks | Chain ID : ojo-devnet <<<";
echo -e "\e[0m"

# variable
OJO_PF_SOUCE=price-feeder
OJO_PF_VERSION=v0.1.1
OJO_PF_REPO=https://github.com/ojo-network/price-feeder
OJO_VALOPER=$(ojod keys show wallet --bech val -a)
OJO_WALLET=$(ojod keys show wallet -a)
OJO_PF_PORT=24672


# Set Price Feeder Wallet Name
if [ ! $OJO_PF_WALLET ]; then
        read -p "hello@nodexcapital:~# [ENTER PRICE FEEDER WALLET NAME] > " OJO_PF_WALLET
        echo 'export OJO_PF_WALLET='$OJO_PF_WALLET >> $HOME/.bash_profile
fi

# grab rpc & grpc port
export RPC_PORT=$(grep -A 9 "# TCP or UNIX socket address for the RPC server to listen on" ~/.ojo/config/config.toml | grep -oP '(?<=:)[0-9]+') >> $HOME/.bash_profile
export GRPC_PORT=$(grep -A 9 "# Address defines the gRPC server address to bind to." ~/.ojo/config/app.toml | grep -oP '(?<=:)[0-9]+') >> $HOME/.bash_profile

echo "Verify the information below before proceeding with the installation!"
echo ""
echo -e "OJO PRICE FEEDER WALLET NAME      : \e[1m\e[35m$OJO_PF_WALLET\e[0m"
echo -e "OJO PRICE FEEDER VERSION          : \e[1m\e[35m$OJO_PF_VERSION\e[0m"
echo -e "OJO RPC PORT                      : \e[1m\e[35m$RPC_PORT\e[0m"
echo -e "OJO gRPC PORT                     : \e[1m\e[35m$GRPC_PORT\e[0m"
echo -e "OJO PRICE FEEDER PORT             : \e[1m\e[35m$OJO_PF_PORT\e[0m"
echo ""

read -p "Is the above information correct? (y/n) " choice
if [[ $choice == [Yy]* ]]; then

echo "export OJO_PF_SOUCE=${OJO_PF_SOUCE}" >> $HOME/.bash_profile
echo "export OJO_PF_VERSION=${OJO_PF_VERSION}" >> $HOME/.bash_profile
echo "export OJO_PF_REPO=${OJO_PF_REPO}" >> $HOME/.bash_profile
echo "export RPC_PORT=${RPC_PORT}" >> $HOME/.bash_profile
echo "export GRPC_PORT=${GRPC_PORT}" >> $HOME/.bash_profile
echo "export OJO_VALOPER=${OJO_VALOPER}" >> $HOME/.bash_profile
echo "export OJO_WALLET=${OJO_WALLET}" >> $HOME/.bash_profile
echo "export OJO_PF_PORT=${OJO_PF_PORT}" >> $HOME/.bash_profile

else
    echo "Installation cancelled!"
    exit 1
fi

# Package
sudo apt -q update
sudo apt -qy upgrade

# Install GO
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.19.5.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)

# Get testnet version of Ojo Price Feeder
cd $HOME
git clone $OJO_PF_REPO
cd $OJO_PF_SOUCE
git checkout $OJO_PF_VERSION
make build
sudo mv build/$OJO_PF_SOUCE /usr/local/bin
rm $HOME/.ojo-price-feeder -rf

# Prepare Price Feeder Directory
mkdir $HOME/.ojo-price-feeder
mv price-feeder.example.toml $HOME/.ojo-price-feeder/config.toml

# Withdraw Commision
# ojod tx distribution withdraw-rewards $(ojod keys show wallet --bech val -a) --commission --from wallet --chain-id ojo-devnet --gas-adjustment 1.4 --gas auto --gas-prices 0uojo -y

# Make a Price Feeder Wallet
read -p "⚠️ Before proceeding with the installation, you must create a wallet and save the mnemonic phrase! Have you done this? (y/n) " yn

if [[ $yn =~ ^[Yy]$ ]]; then
  echo "Please make sure to backup your mnemonic phrase before continuing with the installation!"

# Create Price Feeder Wallet
  ojod keys add $OJO_PF_WALLET --keyring-backend test
  sleep 10

else
  echo "Installation cancelled!"
  exit 1
fi


# Setup Vars Price Feeder Wallet
OJO_PF_ADDRESS=$(echo -e $OJO_PF_PASS | ojod keys show $OJO_PF_WALLET -a)
echo "export OJO_PF_ADDRESS=${OJO_PF_ADDRESS}" >> $HOME/.bash_profile

# Send 1 OJO to Price Feeder Wallet
ojod tx bank send wallet $OJO_PF_ADDRESS 1000000uojo --from wallet --chain-id ojo-devnet --gas-adjustment 1.4 --gas auto --gas-prices 0uojo -y

# Oracle Tx Delegate
ojod tx oracle delegate-feed-consent $OJO_WALLET $OJO_PF_ADDRESS --from wallet --gas-adjustment 1.4 --gas auto --gas-prices 0uojo -y

# Feeder Delegation
ojod q oracle feeder-delegation $OJO_VALOPER

# Set Price Feeder Config
sed -i "s/^listen_addr *=.*/listen_addr = \"0.0.0.0:${OJO_PF_PORT}\"/;\
s/^address *=.*/address = \"$OJO_PF_ADDRESS\"/;\
s/^chain_id *=.*/chain_id = \"ojo-devnet\"/;\
s/^validator *=.*/validator = \"$OJO_VALOPER\"/;\
s/^backend *=.*/backend = \"$OJO_PF_KEYRING\"/;\
s|^dir *=.*|dir = \"$HOME/.ojo\"|;\
s|^grpc_endpoint *=.*|grpc_endpoint = \"localhost:${GRPC_PORT}\"|;\
s|^tmrpc_endpoint *=.*|tmrpc_endpoint = \"http://localhost:${RPC_PORT}\"|;\
s|^global-labels *=.*|global-labels = [[\"chain_id\", \"ojo-devnet\"]]|;\
s|^service-name *=.*|service-name = \"ojo-price-feeder\"|;" $HOME/.ojo-price-feeder/config.toml


# Create Price Feeder Service
sudo tee /etc/systemd/system/ojo-price-feeder.service > /dev/null <<EOF
[Unit]
Description=Ojo Price Feeder
After=network-online.target

[Service]
User=$USER
ExecStart=$(which price-feeder) $HOME/.ojo-price-feeder/config.toml
Restart=on-failure
RestartSec=30
LimitNOFILE=65535
Environment="PRICE_FEEDER_PASS=$OJO_PF_PASS"

[Install]
WantedBy=multi-user.target
EOF

# Register & start service
sudo systemctl daemon-reload
sudo systemctl enable ojo-price-feeder
sudo systemctl restart ojo-price-feeder

echo -e "\e[1m\e[35mPRICE FEEDER SETUP FINISHED\e[0m"
echo ""
echo -e "CHECK STATUS BINARY : \e[1m\e[35msystemctl status ojo-price-feeder\e[0m"
echo -e "CHECK RUNNING LOGS : \e[1m\e[35mjournalctl -fu ojo-price-feeder -o cat\e[0m"
echo ""

# End