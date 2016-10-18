require 'spec_helper'

if os[:family] == 'redhat'

   describe package('cronie') do
     it { should be_installed }
   end

   describe package('crontabs') do
     it { should be_installed }
   end

   describe service('crond') do
     it { should be_enabled }
     it { should be_running }
   end
elsif ['debian', 'ubuntu'].include?(os[:family])

   describe package('cron') do
     it { should be_installed }
   end

   describe service('cron') do
     it { should be_enabled }
     it { should be_running }
   end
end

describe file('/etc/cron.allow') do
  its(:md5sum) { should eq '74cc1c60799e0a786ac7094b532f01b1' }
end

describe file('/etc/cron.allow') do
  it { should be_mode 644 }
end

describe file('/etc/cron.deny') do
  its(:md5sum) { should eq 'a4c60cf3867f1404d152039e49e3ad2a' }
end

describe file('/etc/cron.deny') do
  it { should be_mode 644 }
end

describe file('/etc/crontab') do
  it { should be_mode 400 }
end