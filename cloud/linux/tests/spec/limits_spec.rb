require 'spec_helper'

if os[:family] == 'redhat'
   describe package('pam') do
     it { should be_installed }
   end
elsif ['debian', 'ubuntu'].include?(os[:family])
   describe package('libpam-runtime') do
     it { should be_installed }
   end
   describe package('libpam-modules') do
     it { should be_installed }
   end
   describe package('libpam-modules-bin') do
     it { should be_installed }
   end
   # describe package('libpam-cap') do
   #   it { should be_installed }
   # end
   describe package('libpam-systemd') do
     it { should be_installed }
   end
   describe package('libpam0g') do
     it { should be_installed }
   end
end

describe file('/etc/security/limits.conf') do
  its(:content) { should match /\* soft core 0/ }
  its(:content) { should match /\* hard core 0/ }
end
