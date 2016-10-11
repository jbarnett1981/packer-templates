#!/bin/bash
DISTRO=$(lsb_release -i | awk '{print $3}')

if [ "$DISTRO" = "CentOS" ]; then
   sudo yum install -y ruby ruby-devel
fi

if [ "$DISTRO" = "Ubuntu" ]; then
   sudo apt-add-repository -y ppa:brightbox/ruby-ng
   sudo apt-get update
   sudo apt-get install -y ruby2.3
   # Not used yet
fi

sudo gem install bundler --no-ri --no-rdoc
cd /tmp/tests
sudo /usr/local/bin/bundle install --path=vendor
sudo /usr/local/bin/bundle exec rake spec