#!/bin/bash

# This just rolls a bunch of commands together. Reeally basic...

# Install prerequisites
sudo apt --assume-yes install git libsndfile1-dev bison flex libasound2-dev flac libav-tools python-pip python-dev virtualenv

# Clone ChucK from github repo, compile and install
cd .. && git clone https://github.com/ccrma/chuck

# Compile and install chuck
cd chuck/src && make linux-alsa && sudo make install && cd -

# Clone the ChucK chugins (plugins) repo:
git clone https://github.com/ccrma/chugins

cd chugins && make linux-alsa && sudo make install && cd ../concrete-mixer

# the following very much temporary
git checkout soundcloud-poc

cp concrete.conf.sample concrete.conf

# Install python components (for Soundcloud functionality):
virtualenv venv && source venv/bin/activate && pip install -r requirements.txt

# Start concrete mixer
./init.sh
