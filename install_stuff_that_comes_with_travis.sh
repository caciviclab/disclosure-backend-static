sudo apt-get update
sudo apt-get install --yes software-properties-common build-essential \
  python python-pip libpython-dev wget unzip zlib1g-dev git
sudo add-apt-repository --yes "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo add-apt-repository --yes ppa:brightbox/ruby-ng
sudo apt-get update
sudo apt-get install --yes ruby2.3 ruby2.3-dev postgresql-9.6 libpq-dev

# Set up the database user
sudo /etc/init.d/postgresql start
sudo -u postgres createuser --superuser root
sudo /etc/init.d/postgresql stop

gem install bundler
