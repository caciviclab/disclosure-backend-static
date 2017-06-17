# Install system level dependencies
set -exuo pipefail
sudo apt-get update -qq
sudo apt-get install wget unzip zlib1g-dev git

# Install application dependencies
cd $TRAVIS_BUILD_DIR
bundle install
pip install -r requirements.txt
