#!/bin/bash

pip install --upgrade pip
#pip install 'urllib3[secure]'
pip install -r requirements.txt
sudo gem install pg bundler
sudo bundle install
