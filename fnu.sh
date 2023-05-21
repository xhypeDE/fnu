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

# Step 1: System update
echo -e "${BLUE}[INFO]${NC} Updating system..."
if sudo apt-get update && sudo apt-get upgrade; then
   echo -e "${GREEN}[SUCCESS]${NC} System updated"
else
   echo -e "${RED}[ERROR]${NC} System update failed. Please check your network connection."
   exit 1
fi

# Step 2: Installing NGINX
echo -e "${BLUE}[INFO]${NC} Installing Nginx"
if sudo apt-get install -y nginx; then
   echo -e "${GREEN}[SUCCESS]${NC} Installed Nginx"
else
   echo -e "${RED}[ERROR]${NC} Nginx installation failed. Please check your network connection."
   exit 1
fi

# Step 3: Opening Firewall for NGINX
echo -e "${BLUE}[INFO]${NC} Configuring Firewall for NGINX and SSH"
if sudo ufw allow "NGINX Full" && sudo ufw allow "OpenSSH"; then
   echo -e "${GREEN}[SUCCESS]${NC} Firewall configured"
else
   echo -e "${RED}[ERROR]${NC} Firewall configuration failed"
   exit 1
fi

# Step 4: Installing Python
read -p "Please enter desired Python version (format: 3.x or 3.xx): " pyVersion
regExPyVersion="^(([3]{1})(\.){1}([0-9]{1,2}))?$"
while [[ ! $pyVersion =~ $regExPyVersion ]]; do
   echo -e "${RED}[ERROR]${NC} Incorrect version format (only 3.x or 3.xx is allowed)"
   read -p "Please enter desired Python version (format: 3.x or 3.xx): " pyVersion
done
if sudo add-apt-repository -y ppa:deadsnakes/ppa && sudo apt-get update && sudo apt-get install -y python$pyVersion; then
   echo -e "${GREEN}[SUCCESS]${NC} Installed Python $pyVersion"
else
   echo -e "${RED}[ERROR]${NC} Python installation failed. Please check your network connection."
   exit 1
fi

# Step 5: Setting up application
read -p "Please enter your application name: " applicationName
echo -e "${BLUE}[INFO]${NC} Setting up Flask-Environment"
read -p "Do you want to clone an existing flask repo? [y/n]: " decisionCloneGit
if [ $decisionCloneGit == "y" ]; then
  sudo apt-get install -y git
  read -p "Git URL: " gitRepoUrl
  git clone $gitRepoUrl /var/www/$applicationName || exit 1
else
  sudo cp -r templates/flask/ /var/www/$applicationName/
fi

# Step 6: Setting up Python virtual environment
sudo apt-get -y install python3-pip
sudo pip install virtualenv
virtualenv /var/www/$applicationName/venv || exit 1
source /var/www/$applicationName/venv/bin/activate || exit 1
pip install -r /var/www/$applicationName/requirements.txt || exit 1

# Step 7: Configuring systemd
echo -e "${BLUE}[INFO]${NC} Configuring Systemd"
sudo cp templates/config_templates/service.txt /etc/systemd/system/$applicationName.service
sudo sed -i "s/\${VAR1}/$applicationName/g" /etc/systemd/system/$applicationName.service
sudo sed -i "s/\${VAR2}/$user/g" /etc/systemd/system/$applicationName.service
sudo systemctl daemon-reload
sudo systemctl start $applicationName
sudo systemctl enable $applicationName

# Step 8: Configuring NGINX to Proxy Requests
echo -e "${BLUE}[INFO]${NC} Configuring NGINX"
read -p "Please enter the domain (e.g., example.com): " domain
sudo cp templates/config_templates/nginx_site_conf.txt /etc/nginx/sites-available/$applicationName
sudo sed -i "s/\${VAR3}/$domain/g" /etc/nginx/sites-available/$applicationName
sudo sed -i "s/\${VAR4}/$user/g" /etc/nginx/sites-available/$applicationName
sudo sed -i "s/\${VAR5}/$applicationName/g" /etc/nginx/sites-available/$applicationName
sudo ln -s /etc/nginx/sites-available/$applicationName /etc/nginx/sites-enabled
sudo systemctl restart nginx
echo -e "${GREEN}[SUCCESS]${NC} NGINX configuration completed. "


# Step 9: Check if the user wants to install SSL Certificate using Certbot
read -p "Do you want to install a SSL Certificate using Certbot? [y/n]: " decisionSSL

# If the user decides to install SSL
if [ "$decisionSSL" = "y" ] || [ "$decisionSSL" = "yes" ]; then

  # Install Certbot and the Nginx plugin
  echo -e "${BLUE}[INFO]${NC} Installing Certbot and its Nginx plugin..."
  sudo apt-get install -y certbot python3-certbot-nginx
  
  # Generate the SSL certificate and configure it to work with Nginx
  echo -e "${BLUE}[INFO]${NC} Generating SSL certificate..."
  sudo certbot --nginx -d $targetDomain -d www.$targetDomain
  
  # If the SSL certificate was successfully generated and configured
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS]${NC} SSL certificate was generated and configured successfully."

    # Setup a cron job for auto-renewal of the SSL certificate
    echo -e "${BLUE}[INFO]${NC} Setting up auto-renewal for the SSL certificate..."
    echo '43 6 * * * certbot renew --post-hook "systemctl reload nginx"' | sudo tee -a /etc/crontab > /dev/null

    # If the cron job was successfully set up
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}[SUCCESS]${NC} Auto-renewal for the SSL certificate has been set up successfully."
    else
      echo -e "${RED}[ERROR]${NC} Failed to set up auto-renewal for the SSL certificate."
    fi
  else
    echo -e "${RED}[ERROR]${NC} Failed to generate and configure SSL certificate."
  fi
else
  echo "Skipping SSL certificate installation..."
fi

echo -e "${GREEN}[SUCCESS]${NC} Script completed successfully!"
