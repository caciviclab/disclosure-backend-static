#!/bin/bash --login

# Here's a way to install old ruby 2.7.1 using rvm on ubuntu bookworm
# https://github.com/rvm/rvm/issues/5209

sudo apt install build-essential
cd ~/Downloads
wget https://www.openssl.org/source/openssl-1.1.1t.tar.gz
tar zxvf openssl-1.1.1t.tar.gz
cd openssl-1.1.1t
./config --prefix=$HOME/.openssl/openssl-1.1.1t --openssldir=$HOME/.openssl/openssl-1.1.1t
make
make install
rm -rf ~/.openssl/openssl-1.1.1t/certs
ln -s /etc/ssl/certs ~/.openssl/openssl-1.1.1t/certs
cd ~
rvm install ruby-2.7.1 --with-openssl-dir=$HOME/.openssl/openssl-1.1.1t # replace ruby-x.x.x to install other older versions

rvm use 2.7.1
