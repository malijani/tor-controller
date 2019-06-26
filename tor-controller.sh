#!/bin/bash

#the TOR controller script to configure or check tor in linux
#Copyright (C) 2019  VirtualDemon

#This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

#set -x # Enable for debugging

# the tools that we need in this script
#neededTools="tor torsocks curl pastebinit privoxy"
# the suffix to set on file name to be unique
suffix=$(date "+%y-%m-%d.%H:%M:%S")

# function to check internet connection
function CheckInternetConnection() {
if ping -q -c 2 -W 1 8.8.8.8 >/dev/null; then
  echo "internet connection detected!"
else
    echo "internet is down! please check your connection..."
    exit
fi
}


# function to handle tor config and service
function HandleTor() {
# check torrc existence and create backup from it
if [ -f "/etc/tor/torrc" ]; then
    echo "Backing up the old torrc..."

    sudo cp /etc/tor/torrc /etc/tor/torrc-$suffix
fi

# check if tor service is already running and stop it
if [[ $(ps -ef | grep "/usr/bin/tor" | grep -v grep) ]]
then
    echo "tor is running... stopping it!"
    sudo systemctl stop tor
else
    echo "tor is not running... going on!"
fi
}


# function to enable and start tor service
function StartAndEnableService() {
echo "starting tor service!"
sudo systemctl daemon-reload 2> /dev/null
sudo systemctl enable --now tor.service 2> /dev/null
sudo systemctl start tor.service
}


# function to download and install obfs4proxy in arch
function GetObfs4proxy() {
echo "installing obfs4proxy form archlinuxcn"
OBFSPROXY_PACKAGE=$(curl  http://repo.archlinuxcn.org/x86_64/ |sed 's/<\/\?[^>]\+>//g'| grep obfs4proxy | awk '{ print $1 }' | head -1)
curl -s -o $OBFSPROXY_PACKAGE http://repo.archlinuxcn.org/x86_64/$OBFSPROXY_PACKAGE
sudo pacman -U obfs4proxy*.tar.xz --needed --noconfirm
}


# function to add template config file into /etc/tor/torrc
function AddConfig() {
echo '
#UseBridges 1
#Bridge obfs4 194.135.89.71:443 5D21705C1F5364C2C965C7102C9F0A984E687684 cert=nz/53KYM6QIvReGaC5eAsosEPPXVW9B+EdENFd9yMjaUmKcHLX/149gxBjsXlUeZZi9IFw iat-mode=0
#Bridge obfs4 204.13.164.110:33742 B31A7DAD9AACEDDB9915A16617BB8F06BA429D6B cert=d8iZDGoQ6OwLZRWbuyb+3lK0ESwCl5u8mV7rAbMte6pDqEeR5DoRRa5yKiPIiianX9HdSQ iat-mode=0
#Bridge obfs4 38.229.33.146:44950 969D071BD89A68C15949156CD1CA29A33AF635C2 cert=vbah6jDkKS0NRqW1xgKg6Kd3Unr1P125vDvD9FbYodZ/fsqQ/MWDK277PNAJiGudzHEBGg iat-mode=1
#Bridge obfs4 194.135.89.71:443 5D21705C1F5364C2C965C7102C9F0A984E687684 cert=nz/53KYM6QIvReGaC5eAsosEPPXVW9B+EdENFd9yMjaUmKcHLX/149gxBjsXlUeZZi9IFw iat-mode=0
#Bridge obfs4 204.13.164.110:33742 B31A7DAD9AACEDDB9915A16617BB8F06BA429D6B cert=d8iZDGoQ6OwLZRWbuyb+3lK0ESwCl5u8mV7rAbMte6pDqEeR5DoRRa5yKiPIiianX9HdSQ iat-mode=0
#Bridge obfs4 38.229.33.146:44950 969D071BD89A68C15949156CD1CA29A33AF635C2 cert=vbah6jDkKS0NRqW1xgKg6Kd3Unr1P125vDvD9FbYodZ/fsqQ/MWDK277PNAJiGudzHEBGg iat-mode=1
#Bridge obfs4 148.71.91.18:34731 1084EECA4DF30A829CC5D756B3D14CF59A06D813 cert=e93hwcEAiR5toCbjc/eSncdOHep+ixuiuULFdYrSnYGpH9LDST6VHQzSFINiO0npXkCzeg iat-mode=0
#Bridge obfs4 158.58.171.86:443 1E60C4F078A4081BA74B66E1F6B7061671DF2500 cert=/weFThSm9kbWV8euW4ptcUJf1TYf5CixrKhpEQ6L9hgG48QrmOSj+wywVoCoxVJTe4cpBg iat-mode=0
#Bridge obfs4 13.58.29.242:9443 0C58939A77DA6B6B29D4B5236A75865659607AE0 cert=OylWIEHb/ezpq1zWxW0sgKRn+9ARH2eOcQOZ8/Gew+4l+oKOhQ2jUX/Y+FSl61JorXZUWA iat-mode=0
#Bridge obfs4 86.190.211.234:33911 3B6B01A876BDC1FED8730B7F1B669859D8139491 cert=Cq5XH99F9qu2Qhx3MT5U269FHwDwoDhnqVMXK0zOFCkGWf22Nk3y7ui64n795gV08P87WA iat-mode=0
#Bridge obfs4 73.13.225.56:9443 F0B6CE3543763E042E51FA2C146011AFEF87DF8D cert=RBIBaN8T4DZbX3gGLuw7NXecYKLp2wtKZjAbgDnzQ776oTm/BSVQ+NvdilzifO4SsBz2Rw iat-mode=0
#Bridge obfs4 68.34.126.30:43890 E9DE2759C467A47EF243ED451BBF77798688C7B0 cert=FCXfrlzan73POrB3D8VQyKeVQkY1MUc9k0G3zmRFqaKJrcgWrXAuhIeiBRg3jm/Z9pvpMA iat-mode=0
#Bridge obfs4 194.135.89.71:443 5D21705C1F5364C2C965C7102C9F0A984E687684 cert=nz/53KYM6QIvReGaC5eAsosEPPXVW9B+EdENFd9yMjaUmKcHLX/149gxBjsXlUeZZi9IFw iat-mode=0
#Bridge obfs4 204.13.164.110:33742 B31A7DAD9AACEDDB9915A16617BB8F06BA429D6B cert=d8iZDGoQ6OwLZRWbuyb+3lK0ESwCl5u8mV7rAbMte6pDqEeR5DoRRa5yKiPIiianX9HdSQ iat-mode=0
#Bridge obfs4 38.229.33.146:44950 969D071BD89A68C15949156CD1CA29A33AF635C2 cert=vbah6jDkKS0NRqW1xgKg6Kd3Unr1P125vDvD9FbYodZ/fsqQ/MWDK277PNAJiGudzHEBGg iat-mode=1
#Bridge obfs4 69.162.169.229:7336 36366CA74CB5D7958A73BEB5681135F627DC4F05 cert=bxE0qAN4Um6XGBZ6beZGJM66vMRH/1uvf6hjwWWTO5rALH/bPkq9ktTVtyhhy1vO3YbwMA iat-mode=0
#Bridge obfs4 80.44.48.88:62011 01878F1B89B4C7FC3F64A788D93134E8F8D388A3 cert=v9K1t5Qzjd1Gi8xJ+DNY6scuJI0KgPr33+BiYJL2Y482M7eOpvWU3QiO1XcXnDvDiJUcXQ iat-mode=0
#Bridge obfs4 185.86.148.232:1587 F54B25513D22F885D40B92D63B778F6A5CA7BB4E cert=VuoDGE2bJZYkVTXM2AFTSvcOXiGohzJ9INSAiWKvkI7LDpXX+ysqgk9TNX8YVtPanuFUPQ iat-mode=1
#Bridge obfs4 45.55.52.78:9443 F0E2B678833F42E92F9C1F8E697FCD862463E85E cert=Fyhk+OyA3C0NisrhMU588ipGkS52vV+/WhZdSNyxfVkt0n7k59bWbXd9tN+MZTRM1mgMBQ iat-mode=0
#Bridge obfs4 107.170.74.251:9443 09CA998F792A04DD80CEBE767184A023F0A36B62 cert=qRkRVTz9H6wBo/UexqnukLTMtd7MR3IEcvdgO7jSuuYAaC34Ibkwv+cQghBJ5LlpnzXVYg iat-mode=0
#Bridge obfs4 139.162.190.187:9443 512E9A084DC65204A74AB9E22B4433E141719A0C cert=XyhkJAigScxHpTatVzco5gaylAYbI3DuMpdMobsQn4+2j1yilmV1lcv9mFEZgg0sdQN9Lw iat-mode=0
#Bridge obfs4 207.148.9.163:22995 475ABC68E384608747ABF34C61E454EF18B7F578 cert=EMBTWIJrxUqc/TmlzOcQjmNXaUlfKVuswtVz2NKrqrlbVsF0RdNm/duuHJeTyhPyaCrnfA iat-mode=0
#Bridge obfs4 194.132.209.170:36441 B16B4B1B10910B6EC4A3E713297C4EAE9DFB5229 cert=SzdrMUoL49NrQ0WpTy3dw26MlxNAcvD3lLFqZDrAA/euN++77WueeirzoV2OU5QpJplfUQ iat-mode=0
#Bridge obfs4 154.35.22.11:443 A832D176ECD5C7C6B58825AE22FC4C90FA249637 cert=YPbQqXPiqTUBfjGFLpm9JYEFTBvnzEJDKJxXG5Sxzrr/v2qrhGU4Jls9lHjLAhqpXaEfZw iat-mode=0
#Bridge obfs4 154.35.22.10:80 8FB9F4319E89E5C6223052AA525A192AFBC85D55 cert=GGGS1TX4R81m3r0HBl79wKy1OtPPNR2CZUIrHjkRg65Vc2VR8fOyo64f9kmT1UAFG7j0HQ iat-mode=0
#Bridge obfs4 154.35.22.13:443 FE7840FE1E21FE0A0639ED176EDA00A3ECA1E34D cert=fKnzxr+m+jWXXQGCaXe4f2gGoPXMzbL+bTBbXMYXuK0tMotd+nXyS33y2mONZWU29l81CA iat-mode=0
#Bridge obfs4 154.35.22.12:80 00DC6C4FA49A65BD1472993CF6730D54F11E0DBB cert=N86E9hKXXXVz6G7w2z8wFfhIDztDAzZ/3poxVePHEYjbKDWzjkRDccFMAnhK75fc65pYSg iat-mode=0
#Bridge obfs4 154.35.22.9:80 C73ADBAC8ADFDBF0FC0F3F4E8091C0107D093716 cert=gEGKc5WN/bSjFa6UkG9hOcft1tuK+cV8hbZ0H6cqXiMPLqSbCh2Q3PHe5OOr6oMVORhoJA iat-mode=0
#Bridge obfs4 45.32.243.248:45387 3B3C0EBEF52BDF1B547771F465CE438BA20613DE cert=aBGFd6O0Sue189rBFvE3BNfwxk3wLY6VX3MLa+yAAk2lsPohqQLgOnEkoa7752e/CehmaQ iat-mode=0
#Bridge obfs4 85.195.247.105:42501 9F548604BD5AB011F13301D843F83E1A8DA57A0D cert=I5iJp4egNJbz+20QsW02sgSBC6giNQhsbGtLATeAgzwSWdJfxvXbAY+hhWlBqmpuo+plKQ iat-mode=0
#Bridge obfs4 92.243.11.60:37601 890A93FB1C142311441E7E793F5CA83773D3FB6C cert=jd7MwLG2SXhFALGcuMpCJXi+TW4xlrJdx3A8D4e/2L2jSeS2oALoEbV+raBzd/lk5r+aUA iat-mode=0
#Bridge obfs4 94.242.249.6:44939 E53EEA7DE6E170328F0A2C4338EE4E4DC2398218 cert=VpistQqdnS5zgkARR3he8rt03OrKhk2oobUUhLmFWAWK27pYMvjrBi6zAn1ebIcPH2xbcQ iat-mode=0
#Bridge obfs4 194.132.209.64:57381 9CB2FE1A1DE610E159C517DA48530EB9853952D9 cert=IBEkNg/igqYfT5nxcBtS1Y72WYRR5XbYVS+qpPRBtxEz7g6l8fnov5k28WEfvPseR1+2MA iat-mode=0
#Bridge obfs4 194.132.209.83:56476 FD0CDF376B9BD679DBAA166BC5CAF2A45574C91D cert=tMHzz3dBh4in3RzycNiv5V5Rf2p1nVdUi28rdoPTLCHPc+kr5BO7IKJvVBGXbDW4AUbeTg iat-mode=0
#Bridge obfs4 194.132.209.170:36441 B16B4B1B10910B6EC4A3E713297C4EAE9DFB5229 cert=SzdrMUoL49NrQ0WpTy3dw26MlxNAcvD3lLFqZDrAA/euN++77WueeirzoV2OU5QpJplfUQ iat-mode=0
#Bridge obfs4 154.35.22.11:443 A832D176ECD5C7C6B58825AE22FC4C90FA249637 cert=YPbQqXPiqTUBfjGFLpm9JYEFTBvnzEJDKJxXG5Sxzrr/v2qrhGU4Jls9lHjLAhqpXaEfZw iat-mode=0
#Bridge obfs4 154.35.22.10:80 8FB9F4319E89E5C6223052AA525A192AFBC85D55 cert=GGGS1TX4R81m3r0HBl79wKy1OtPPNR2CZUIrHjkRg65Vc2VR8fOyo64f9kmT1UAFG7j0HQ iat-mode=0
#Bridge obfs4 154.35.22.13:443 FE7840FE1E21FE0A0639ED176EDA00A3ECA1E34D cert=fKnzxr+m+jWXXQGCaXe4f2gGoPXMzbL+bTBbXMYXuK0tMotd+nXyS33y2mONZWU29l81CA iat-mode=0
#Bridge obfs4 154.35.22.12:80 00DC6C4FA49A65BD1472993CF6730D54F11E0DBB cert=N86E9hKXXXVz6G7w2z8wFfhIDztDAzZ/3poxVePHEYjbKDWzjkRDccFMAnhK75fc65pYSg iat-mode=0
#Bridge obfs4 154.35.22.9:80 C73ADBAC8ADFDBF0FC0F3F4E8091C0107D093716 cert=gEGKc5WN/bSjFa6UkG9hOcft1tuK+cV8hbZ0H6cqXiMPLqSbCh2Q3PHe5OOr6oMVORhoJA iat-mode=0
#Bridge obfs4 85.195.247.105:42501 9F548604BD5AB011F13301D843F83E1A8DA57A0D cert=I5iJp4egNJbz+20QsW02sgSBC6giNQhsbGtLATeAgzwSWdJfxvXbAY+hhWlBqmpuo+plKQ iat-mode=0
#Bridge obfs4 92.243.11.60:37601 890A93FB1C142311441E7E793F5CA83773D3FB6C cert=jd7MwLG2SXhFALGcuMpCJXi+TW4xlrJdx3A8D4e/2L2jSeS2oALoEbV+raBzd/lk5r+aUA iat-mode=0
#Bridge obfs4 94.242.249.6:44939 E53EEA7DE6E170328F0A2C4338EE4E4DC2398218 cert=VpistQqdnS5zgkARR3he8rt03OrKhk2oobUUhLmFWAWK27pYMvjrBi6zAn1ebIcPH2xbcQ iat-mode=0
#Bridge obfs4 194.132.209.64:57381 9CB2FE1A1DE610E159C517DA48530EB9853952D9 cert=IBEkNg/igqYfT5nxcBtS1Y72WYRR5XbYVS+qpPRBtxEz7g6l8fnov5k28WEfvPseR1+2MA iat-mode=0
#Bridge obfs4 194.132.209.83:56476 FD0CDF376B9BD679DBAA166BC5CAF2A45574C91D cert=tMHzz3dBh4in3RzycNiv5V5Rf2p1nVdUi28rdoPTLCHPc+kr5BO7IKJvVBGXbDW4AUbeTg iat-mode=0
#Bridge obfs4 52.14.166.220:9443 4276CBF97399A90A6EA32E1256ADDCE38E987E01 cert=qD4MusGx5DyiTi9t4tEaQyIK9xO5MQa8iJ1Sr4gOR/maetZZUvmyBBCDxi2Ox29bBAKZeQ iat-mode=0
#Bridge obfs4 138.68.244.99:9443 050D4D052D0877D55FA4EADCD844C433FFE39EA2 cert=qUqF/q6yNaQuIDjms6cNu1Dc7eV4LbhhUw9bnoOQQobPcE33gW//oYkA/ehxOIkZuLaWVw iat-mode=0
#ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy managed
VirtualAddrNetwork 10.192.0.0/10
AutomapHostsOnResolve 1
TransPort 9040
DNSPort 5353
#ClientUseIPv6 1 
#SocksListenAddress 127.0.0.1:9200
#SocksPort 9200
#ExitNodes {pl},{de},{fr}
#ExitNodes {us}
#StrictNodes 1 ' | sudo tee /etc/tor/torrc
}


# function to change tor systemd service for debian based distros
function CorrectService() {
echo '
# This service is actually a systemd target,
# but we are using a service since targets cannot be reloaded.
[Unit]
Description=Anonymizing overlay network for TCP (multi-instance-master)
[Service]
User=debian-tor
Type=simple
RemainAfterExit=yes
ExecStart=/usr/bin/tor -f /etc/tor/torrc
ExecReload=/usr/bin/kill -HUP $MAINPID
KillSignal=SIGINT
LimitNOFILE=8192
PrivateDevices=yes
[Install]
WantedBy=multi-user.target' | sudo tee /lib/systemd/system/tor.service
# create link
sudo ln -sf /lib/systemd/system/tor.service /etc/systemd/system/multi-user.target.wants/tor.service
}


# function to control tor service
function ControlTor() {
userCounts=$1
torCounter=0
while true
do
    sleep 10
    if [ $(curl -s -x socks5://localhost:9050 icanhazip.com) ]
    then
	echo "$(date "+%b %d %H:%M:%S")- tor is healthy!"
	((torCounter++))
    else
	echo "restarting tor. please wait..."	
    fi
    if [[ ! -z $userCounts && $torCounter -eq $userCounts  ]]
    then
	echo "exitting..."
	exit
    fi
done
} 


# function to set distro base
function SetDistro() {
# check the type of distro (checking with the package manager: apt=>Debian ; pacman=>archlinux)
if [ $(which apt) ]
then
    distro="debian"
elif [ $(which pacman) ]
then
    distro="arch"
else
    echo "this script doesn't support your system. exiting."
    exit
fi

}


# function to enable or disable bridges in /etc/tor/torrc configuration file
function EnableDisableBridges() {
if [ $1 == "disable" ]
then
	sudo sed -i 's/^Bridge/#Bridge/g' /etc/tor/torrc
	sudo sed -i 's/^UseBridges/#UseBridges/' /etc/tor/torrc
	sudo sed -i 's/^ClientTransportPlugin/#ClientTransportPlugin/' /etc/tor/torrc
elif [ $1 == "enable" ]
then
	sudo sed -i 's/^#Bridge/Bridge/g' /etc/tor/torrc
	sudo sed -i 's/^#UseBridges/UseBridges/' /etc/tor/torrc
	sudo sed -i 's/^#ClientTransportPlugin/ClientTransportPlugin/' /etc/tor/torrc
else
	echo "There is a problem with EnableDisableBridges() please check the source..."
	exit
fi
}


# function to ask user to enable bridges or not?!
function AskUserToEnableBridges() {
read -p "Do you want to use bridges? (y/n): " choice
case "$choice" in 
    y|Y|yes|Yes|YES ) EnableDisableBridges "enable" ;;
    n|N|no|No|NO ) echo "Your using tor without bridges..." ;;
    * ) echo "invalid" ;;
esac
}

# function to Install tor on system (developed for debian and arch based distrobutions!)
function Installer() {
SetDistro    
# install tor and needed tools for detected distro!
if [ $distro=="debian" ]
then
    CheckInternetConnection
    sudo apt update -y
    HandleTor
    sudo apt install tor obfs4proxy torsocks -y
    AddConfig
    AskUserToEnableBridges
    CorrectService
    StartAndEnableService
    ControlTor 10
    
elif [ $distro=="archlinux" ]
then
    CheckInternetConnection
    sudo pacman -Sy
    HandleTor
    sudo pacman -S tor torsocks --noconfirm --needed --force
    GetObs4proxy
    AddConfig
    AskUserToEnableBridges
    StartAndEnableService
    ControlTor 10
fi
}


# function to transparent tor proxy
function TransparentTorProxy() {
if [ $1 == "start-transparent" ]
then
    # destinations you do not want routed through Tor
    NON_TOR="192.168.1.0/24 192.168.0.0/24"
    # the UID Tor runs as, change this accordingly for your OS
    TOR_UID="43"
    # Tor's TransPort
    TRANS_PORT="9040"
    sudo iptables -F
    sudo iptables -t nat -F
    sudo iptables -t nat -A OUTPUT -m owner --uid-owner $TOR_UID -j RETURN
    sudo iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353
    for NET in $NON_TOR 127.0.0.0/9 127.128.0.0/10; do
	sudo iptables -t nat -A OUTPUT -d $NET -j RETURN
    done
    sudo iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports $TRANS_PORT
    sudo iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    for NET in $NON_TOR 127.0.0.0/8; do
	sudo iptables -A OUTPUT -d $NET -j ACCEPT
    done
    sudo iptables -A OUTPUT -m owner --uid-owner $TOR_UID -j ACCEPT
    sudo iptables -A OUTPUT -j REJECT
elif [ $1 == "stop-transparent" ]
then
    sudo iptables -P INPUT ACCEPT
    sudo iptables -P OUTPUT ACCEPT
    sudo iptables -P FORWARD ACCEPT
    sudo iptables -F INPUT
    sudo iptables -F OUTPUT
    sudo iptables -F FORWARD
else
    echo "maybe there's a problem with input argument in TransparentTorProxy() function."
    exit
fi
}


# function to paste content somewhere
function Paster() {
inputText=$@
# its better to install pastebinit on your system
if [ $(which pastebinit) ]
then
$inputText pastebinit -b paste.openstack.org
    if [ $? != 0 ]
    then
	$inputText pastebinit -b slexy.org
    fi
elif [ $(which wgetpaste) ]
then
$inputText wgetpaste
elif [ $(which fpaste)]
then
$inputText fpaste
elif [ $(which upaste) ]
then
$inputText upaste
else
    $inputText  curl --upload-file - https://transfer.sh/torBridges-$suffix
fi 2>/dev/null
} 


# function to upload bridges for orbot or upload /etc/tor/torrc entirely
function UploadConf() {
if [ $1 == "upload-conf" ]
then
    Paster "cat /etc/tor/torrc"
elif [ $1 == "upload-bridges" ]
then
    bridges=$(grep "^Bridge\|^#Bridge" /etc/tor/torrc)
    echo "$bridges" > /tmp/bridges-$suffix
    Paster "cat /tmp/bridges-$suffix"
elif [ $1 == "upload-orbot" ]
then
    bridges=$(grep "^Bridge\|^#Bridge" /etc/tor/torrc | sed -s 's/^Bridge/\n/g')
    echo "$bridges" > /tmp/bridges-$suffix
    Paster "cat /tmp/bridges-$suffix"
else
    echo "maybe there's a problem with input rgument in UploadConf() function."
    exit
fi
}


# function to get new bridges(working on it!)
#function GetBridges(){
#}


# function to print script usage
function ShowUsage() {
cat << EOF
this is a simple script to control tor service on your linux system!

usage: tor-controller.sh --argument-input

options: --install		-i
	 --check-service	-cs
	 --transparent-proxy	-tp
	 --intransparent-proxy	-ip
	 --upload-conf		-uc
	 --upload-bridge	-ub
	 --upload-bridge-orbot	-ubo
EOF
}


#### Control Arguments
# check the count of them
if [ "$#" -ne 1 ]; then
    ShowUsage
    exit
fi


# check input arguments
# main script
inputArgument=$1
case $inputArgument in
    -i|--install ) Installer ;;
    -cs|--check-service ) ControlTor ;;
    -tp|--transparent-proxy ) TransparentTorProxy "start-transparent" ;;
    -ip|--intransparent-proxy ) TransparentTorProxy "stop-transparent" ;;
    -uc|--upload-conf ) UploadConf "upload-conf" ;;
    -ub|--upload-bridge ) UploadConf "upload-bridge" ;;
    -ubo|--upload-bridge-orbot ) UploadConf "upload-orbot" ;;
    *) ShowUsage ;;
esac
	     
