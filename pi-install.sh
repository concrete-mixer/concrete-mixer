#!/bin/bash

# This just rolls a bunch of commands together. Reeally basic...


# ensure packages are uptodate. This can take a while on a pi
sudo apt-get update && sudo apt-get upgrade

# Install prerequisites
sudo apt update && sudo apt --assume-yes install git libsndfile1-dev bison flex libasound2-dev flac avconv libav-tools python-pip python-dev virtualenv

# Clone ChucK from github repo, compile and install
git clone https://github.com/ccrma/chuck

# Compile and install chuck
cd chuck/src && make linux-alsa && sudo make install && cd -

# Clone the ChucK chugins (plugins) repo:
git clone https://github.com/ccrma/chugins

cd chugins && make linux-alsa && sudo make install && cd -

# Install Concrete Mixer
git clone https://github.com/concrete-mixer/concrete-mixer

cp concrete.conf.sample concrete.conf

git checkout soundcloud-poc

# Install python components (for Soundcloud functionality):
virtualenv venv && pip install -r requirements.txt

# Start concrete mixer
./init.sh
