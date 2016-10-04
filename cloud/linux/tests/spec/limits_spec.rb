require 'spec_helper'

describe package('pam') do
  it { should be_installed }
end

describe file('/etc/security/limits.conf') do
  its(:content) { should match /\* soft core 0/ }
  its(:content) { should match /\* hard core 0/ }
end
