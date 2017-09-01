#!/bin/bash
# This is a shell script for starting a django project on ubuntu
# using https://github.com/MikeHannon/DjangoDeployment as a reference
echo "Whats the repository name?"
read repo
echo "Whats the project name?"
read proj
echo "Now whate is the url for your code?"
read url
sudo apt-get update
sudo apt-get install python-pip python-dev nginx git
sudo apt-get update
sudo pip install virtualenv
git clone $url
virtualenv venv
source venv/bin/activate
cd $repo
# You may run into errors installing the requiremnets.txt, I ran into issues
# installing mysql and had to manually install the requirements and install 
# mysql-dev individually
pip install -r requirments.txt
pip install django bcrypt django-extensions
pip install gunicorn
cd $proj
echo "Now you need to edit stuff..."
sudo vim settings.py
cd ..
echo "Say yes"
python manage.py collectstatic
echo "Testing gunicorn! Press CTRL-C to stop"
gunicorn --bind 0.0.0.0:8000 $proj.wsgi:application
cat >/etc/init/gunicorn.conf <<text
description "Gunicorn application server handling our project"
start on runlevel [2345]
stop on runlevel [!2345]
respawn
setuid ubuntu
setgid www-data
chdir /home/ubuntu/$repo
exec venv/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/$repo/$proj.sock $proj.wsgi:application
text
sudo service gunicorn start
echo "Edit Nginx"
sudo vim /etc/nginx/sites-available/$proj
sudo ln -s /etc/nginx/sites-available/$proj /etc/nginx/sites-enabled
sudo nginx -t
sudo rm /etx/nginx/sites-enabled/default
sudo service nginx restart
echo "Now your site should be running!"
