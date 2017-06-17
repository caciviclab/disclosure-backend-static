# Install system level dependencies
set -exuo pipefail
sudo apt-get update
sudo apt-get install wget unzip zlib1g-dev git

# Set up the database
sudo /etc/init.d/postgresql start
sudo -u postgres createuser --superuser root
sudo /etc/init.d/postgresql stop

# Install application dependencies
cd $TRAVIS_BUILD_DIR
bundle install
pip install -r requirements.txt
