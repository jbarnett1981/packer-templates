require 'spec_helper'

describe package('epel-release') do
  it { should be_installed }
end

#commenting out until further notice
#describe file('/etc/yum.repos.d/Tableau.repo') do
#  its(:md5sum) { should eq 'c9139da99cef53a93c494df0aa4e0a3e' }
#end

describe file('/etc/yum.conf') do
  its(:content) { should match /metadata_expire=1800/ }
  its(:content) { should match /installonlypkgs=kernel kernel\*/ }
end
