if [ ! -d "AWSLab" ]
then
    git clone https://github.com/DanHatesNumbers/AWSLab
else
    cd AWSLab && git pull && cd ..
fi
sudo cp AWSLab/salt/files/* /var/salt/base/
sudo cp AWSLab/salt/state/* /var/salt/base/