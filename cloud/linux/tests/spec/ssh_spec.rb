require 'spec_helper'

describe package('openssh-server') do
  it { should be_installed }
end


if os[:family] == 'redhat'

   describe service('sshd') do
     it { should be_enabled }
     it { should be_running }
   end

elsif ['debian', 'ubuntu'].include?(os[:family])
   describe service('ssh') do
      it { should be_enabled }
      it { should be_running }
   end
end

describe file('/etc/issue') do
  its(:md5sum) { should eq '32c5527ffe1a2b219b067820e1a1ca48' }
end

describe file('/etc/issue.net') do
  its(:md5sum) { should eq '32c5527ffe1a2b219b067820e1a1ca48' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match /ClientAliveInterval 300/ }
  its(:content) { should match /Banner \/etc\/issue/ }
end