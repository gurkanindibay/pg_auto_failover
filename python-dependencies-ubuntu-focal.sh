#Libcurl
sudo apt install libcurl4-openssl-dev libssl-dev
pipenv install pycurl

#pipenv
sudo apt install python-is-python3
sudo apt-get install python3-pip
echo 'export PATH = /home/vagrant/.local/bin:$PATH' >> /home/vagrant/.bashrc
pip3 uninstall virtualenv || true
pip3 install virtualenv==20.0.23
