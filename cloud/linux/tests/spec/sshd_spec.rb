require 'spec_helper'

describe package('openssh-server') do
  it { should be_installed }
end

describe service('sshd') do
  it { should be_enabled }
  it { should be_running }
end

describe file('/etc/issue') do
  its(:md5sum) { should eq '32c5527ffe1a2b219b067820e1a1ca48' }
end

describe file('/etc/issue.net') do
  its(:md5sum) { should eq '32c5527ffe1a2b219b067820e1a1ca48' }
end

describe file('/etc/ssh/sshd_config') do
  its(:content) { should match /PermitRootLogin yes/ }
  its(:content) { should match /UsePrivilegeSeparation yes/ }
  its(:content) { should match /ClientAliveInterval 300/ }
  its(:content) { should match /Banner \/etc\/issue/ }
end
