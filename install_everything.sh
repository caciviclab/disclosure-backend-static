# Install system level dependencies
set -exuo pipefail
apt-get update
apt-get install --yes software-properties-common build-essential \
  python python-pip libpython-dev wget unzip zlib1g-dev git
add-apt-repository --yes "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get install --yes postgresql-9.6 libpq-dev

# Set up the database
/etc/init.d/postgresql start
sudo -u postgres createuser --superuser root
/etc/init.d/postgresql stop

# Install application dependencies
cd $TRAVIS_BUILD_DIR
bundle install
pip install -r requirements.txt
