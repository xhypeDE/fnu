# FNU
![alt text](https://github.com/xhypeDE/fnu/blob/babe33e3ec0f3999b2f48f997a9fccfd6850ae19/fnu_thumbnail.png)
A simple Bash-Script to deploy a Flask/Nginx server using Gunicorn on Ubuntu.

To deploy simply make sure you have git installed on the ubuntu server to clone the repository.


## Steps to deploy

* Create a new sudo user on a fresh ubuntu installation
* Grant the user all privileges and enable "NOPASSWD"
* Switch to the new user
<br>`su (your username)`
* Switch to the home directory
<br>`cd`

* Clone the repository
<br>`git clone https://github.com/xhypeDE/fnu.git`
* Change to the cloned repository
<br>`cd fnu`
* Run the bash script
<br>`bash fnu.sh`

## Included files
* `fnu.sh` bash script
* `/templates` directory containing template files
* `/templates/config_templates` template files for config_files like nginx or the service daemon
* `/templates/flask` a basic flask structure template
* `/generated_files` will be created during the script and contains the generated config files that will be used for nginx conf and application.service daemon


## Current functions
* Fetches updates
* Installs NGINX
* Asks for desired python version (3.x)
* Installs python
* Creates a basic flask setup with venv or clones an existing flask repo
* Installs gunicorn
* Sets up config files and gunicorn daemon
* Asks for domain and applicationname to use
* Configures NGINX to use the socket
* Enable SSL certificate generation with certbot
* Implements a cronjob for auto-renewal of the SSL Certificate
