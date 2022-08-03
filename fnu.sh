 #!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

echo "
███████╗███╗   ██╗██╗   ██╗                                   
██╔════╝████╗  ██║██║   ██║                                   
█████╗  ██╔██╗ ██║██║   ██║                                   
██╔══╝  ██║╚██╗██║██║   ██║                                   
██║     ██║ ╚████║╚██████╔╝                                   
╚═╝     ╚═╝  ╚═══╝ ╚═════╝                                    
                                                              
██████╗ ██╗   ██╗    ██╗  ██╗██╗  ██╗██╗   ██╗██████╗ ███████╗
██╔══██╗╚██╗ ██╔╝    ╚██╗██╔╝██║  ██║╚██╗ ██╔╝██╔══██╗██╔════╝
██████╔╝ ╚████╔╝      ╚███╔╝ ███████║ ╚████╔╝ ██████╔╝█████╗  
██╔══██╗  ╚██╔╝       ██╔██╗ ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══╝  
██████╔╝   ██║       ██╔╝ ██╗██║  ██║   ██║   ██║     ███████╗
╚═════╝    ╚═╝       ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝

"
echo "Starting Express Installation of FNU"
echo "Updating..."
sudo apt-get update && sudo apt-get upgrade
echo "Installing Nginx"
sudo apt-get install nginx 
RESULT=$?
if [ $RESULT -eq 0 ]; then
   echo -e "${GREEN}SUCCESS:${NC} Installed nginx"
else
  echo -e "${ORANGE}WARNING:${NC} Nginx installation failed"
  read -p "Proceed anyways? (Proceed only if NGINX was already installed) [y/n]: " decisionNginx
  if [ $decisionNginx == no ] | [ $decisionNginx == n ]; then
   echo "Aborting FNU... Goodbye!"
   exit
  fi
fi
echo "Opening Firewall for NGINX"
sudo ufw allow "NGINX Full"
read -p "Please enter desired Python version (form: 3.x): " pyVersion
while [[ ! $pyVersion =~ ^([3]{1})(\.)?([0-9]{1})?$ ]]
do
   echo -e "${RED}ERROR:${NC} Wrong version (Only 3.x is allowed)"
   read -p "Please enter desired Python version (form: 3.x): " pyVersion
done
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install python$pyVersion
read -p "Please enter your application name : " applicationName
read -p "Please enter the name of the desired domain (without www): " targetDomain
while [[ $targetDomain =~ "www." ]];
do
  echo -e "${RED}ERROR:${NC} Please enter your domain without www"
  read -p "Please enter the name of the desired domain (without www): " targetDomain
done
sudo cp -r templates/flask/ ~/$applicationName/
cd ~/$applicationName
sudo apt-get -y install python3-pip
pip install virtualenv
sudo virtualenv venv --python=python3.9
source venv/bin/activate
pip install -r requirements.txt
deactivate

