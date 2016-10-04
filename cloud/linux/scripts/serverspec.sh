#!/bin/bash
sudo yum install -y ruby ruby-devel
sudo gem install bundler --no-ri --no-rdoc
cd /tmp/tests
sudo /usr/local/bin/bundle install --path=vendor
sudo /usr/local/bin/bundle exec rake spec