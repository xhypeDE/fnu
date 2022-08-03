 #!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
NC='\e[0m' # No Color
user="$USER"
sciptDir=$(pwd)

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
echo "${BLUE}[INFO]${NC} Updating..."
sudo apt-get update && sudo apt-get upgrade
echo "${BLUE}[INFO]${NC} Installing Nginx"
sudo apt-get install nginx 
RESULT=$?
if [ $RESULT -eq 0 ]; then
   echo -e "${GREEN}[SUCCESS]${NC} Installed nginx"
else
  echo -e "${YELLOW}[WARNING]${NC} Nginx installation failed"
  read -p "Proceed anyways? (Proceed only if NGINX was already installed) [y/n]: " decisionNginx
  if [ $decisionNginx == no ] | [ $decisionNginx == n ]; then
   echo "Aborting FNU... Goodbye!"
   exit
  fi
fi
echo "${BLUE}[INFO]${NC} Opening Firewall for NGINX"
sudo ufw allow "NGINX Full"
read -p "Please enter desired Python version (form: 3.x): " pyVersion
while [[ ! $pyVersion =~ ^([3]{1})(\.)?([0-9]{1})?$ ]]
do
   echo -e "${RED}[ERROR]${NC} Wrong version (Only 3.x is allowed)"
   read -p "Please enter desired Python version (form: 3.x): " pyVersion
done
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install python$pyVersion
read -p "Please enter your application name : " applicationName
read -p "Please enter the name of the desired domain (without www): " targetDomain
while [[ $targetDomain =~ "www." ]];
do
  echo -e "${RED}[ERROR]${NC} Please enter your domain without www"
  read -p "Please enter the name of the desired domain (without www): " targetDomain
done
echo "${BLUE}[INFO]${NC} Setting up Flask-Environment"
sleep 2
sudo cp -r templates/flask/ ~/$applicationName/
cd ~/$applicationName
sudo apt-get -y install python3-pip
pip install virtualenv
sudo virtualenv venv --python=python3.9
source venv/bin/activate
pip install -r requirements.txt
pip install gunicorn
deactivate
echo "${BLUE}[INFO]${NC} Generating flask daemon file from template"
sleep 1
cd $sciptDir
sudo mkdir generated_files
export VAR1=$applicationName VAR2=$user
envsubst '${VAR1} ${VAR2}' < templates/config_templates/service.txt > generated_files/$applicationName.service
sudo cp generated_files/$applicationName.service /etc/systemd/system/$applicationName.service
sudo systemctl start $applicationName
sudo systemctl enable $applicationName
sudo systemctl is-active --quiet $applicationName.service
if [ $RESULT -eq 0 ]; then
   echo -e "${GREEN}[SUCEESS]${NC} Service is running"
else
  echo -e "${RED}[ERROR]${NC} Installation failed..."
  echo -e "${RED}[ERROR]${NC} Service is not running"
  read -p "Show service status?[y/n]: " decisionService
  if [ $Service == yes ] | [ $decisionNginx == y ]; then
   sudo systemctl status $applicationName.service
   exit
  else
    exit
  fi
fi
export VAR3=$targetDomain VAR4=$user VAR5=$applicationName
envsubst '${VAR3} ${VAR4} ${VAR5}' < templates/config_templates/nginx_site_conf.txt > generated_files/$targetDomain.conf
sudo cp generated_files/$targetDomain.conf /etc/nginx/sites-available/$targetDomain.conf
sudo ln -s /etc/nginx/sites-available/$targetDomain.conf /etc/nginx/sites-enabled/$targetDomain.conf
sudo systemctl restart nginx





