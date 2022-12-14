 #!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
NC='\e[0m' # No Color
user="$USER"
sciptDir=$(pwd)
exec 1>logs/instalation.log 2>&1

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
echo -e "${BLUE}[INFO]${NC} Updating..."
sudo apt-get update && sudo apt-get upgrade
echo -e "${BLUE}[INFO]${NC} Installing Nginx"
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
echo -e "${BLUE}[INFO]${NC} Opening Firewall for NGINX"
sudo ufw allow "NGINX Full"
sudo ufw allow "OpenSSH"
sudo ufw allow "ssh"
sudo ufw enable
read -p "Please enter desired Python version (form: 3.x or 3.xx): " pyVersion
regExPyVersion="^(([3]{1})(\.){1}([0-9]{1,2}))?$"
while [[ ! $pyVersion =~ $regExPyVersion ]]
do
   echo -e "${RED}[ERROR]${NC} Wrong version (Only 3.x is allowed)"
   read -p "Please enter desired Python version (form: 3.x or 3.xx): " pyVersion
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
echo -e "${BLUE}[INFO]${NC} Setting up Flask-Environment"
sleep 2
read -p "Do you want to clone an existing flask repo? [y/n]: " decisionCloneGit
if [ $decisionCloneGit == yes ] | [ $decisionCloneGit == y ]; then
  sudo apt-get install git
  read -p "Git URL: " gitRepoUrl
  cd ~/
  git clone $gitRepoUrl $applicationName
  requirementFile=~/$applicationName/requirements.txt
  if test -f "$requirementFile"; then
    echo -e "${BLUE}[INFO]${NC} Found existing requirements.txt"
  else
    echo -e "${YELLOW}[WARNING]${NC} No requirements.txt found. Using default."
    cp templates/flask/requirements.txt ~/$applicationName/requirements.txt 
  fi
else
  cp -r templates/flask/ ~/$applicationName/  
fi
cd ~/$applicationName
sudo apt-get -y install python3-pip
sudo pip install virtualenv
virtualenv venv --python=python$pyVersion
source venv/bin/activate
pip install -r requirements.txt
pip install gunicorn
deactivate
echo -e "${BLUE}[INFO]${NC} Generating flask daemon file from template"
sleep 1
cd $sciptDir
mkdir generated_files
if [ $RESULT -eq 0 ]; then
   echo -e "${GREEN}[SUCCESS]${NC} Created generated_files directory"
else
  echo -e "${YELLOW}[WARNING]${NC} Generated_files already exists... Overwriting"
  sudo rm -rf generated_files
  mkdir generated_files
  if [ $RESULT -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS]${NC} Created generated_files directory"
  else
    echo -e "${RED}[ERROR]${NC} Couldn't create generated_files directory. Check permissions. 
    Is fnu running in your home directory?"
    echo -e "${RED}[ERROR]${NC} Installation failed..."
    exit
  fi
fi

export VAR1=$applicationName VAR2=$user
envsubst '${VAR1} ${VAR2}' < templates/config_templates/service.txt > generated_files/$applicationName.service
sudo cp generated_files/$applicationName.service /etc/systemd/system/$applicationName.service
sudo systemctl daemon-reload
echo -e "${BLUE}[INFO]${NC} Starting up service"
sudo systemctl start $applicationName
sudo systemctl enable $applicationName
sudo systemctl is-active $applicationName.service
if [ $RESULT -eq 0 ]; then
   echo -e "${GREEN}[SUCCESS]${NC} Service is running"
else
  echo -e "${RED}[ERROR]${NC} Installation failed..."
  echo -e "${RED}[ERROR]${NC} Service is not running"
  sudo systemctl status $applicationName.service
  exit
fi
export VAR3=$targetDomain VAR4=$user VAR5=$applicationName
envsubst '${VAR3} ${VAR4} ${VAR5}' < templates/config_templates/nginx_site_conf.txt > generated_files/$targetDomain.conf
sudo cp generated_files/$targetDomain.conf /etc/nginx/sites-available/$targetDomain.conf
sudo ln -s /etc/nginx/sites-available/$targetDomain.conf /etc/nginx/sites-enabled/$targetDomain.conf
sudo systemctl restart nginx
read -p "Do you want to install a SSL Certificate Certbot? [y/n]: " decisionSSL
if [ $decisionSSL == no ] | [ $decisionSSL == n ]; then
  echo "Okay. Exiting...Goodbye!"
  exit
fi
echo -e "${BLUE}[INFO]${NC} Installing certbot"
sudo apt install certbot python3-certbot-nginx
echo -e "${BLUE}[INFO]${NC} Generating certificate"
sudo certbot --nginx -d $targetDomain -d www.$targetDomain
echo -e "${BLUE}[INFO]${NC} Setting up auto-renewal for certificate"
crontab -l > mycron
echo '43 6 * * * certbot renew --post-hook "systemctl reload nginx"' >> mycron
crontab mycron
rm mycron
echo -e "${GREEN}[SUCCESS]${NC} Enabled SSL for $applicationName"
echo -e "${GREEN}[SUCCESS]${NC} Done! Goodbye"
exit


