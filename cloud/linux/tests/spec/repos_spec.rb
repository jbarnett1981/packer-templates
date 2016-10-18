require 'spec_helper'

if os[:family] == 'redhat'

   describe package('epel-release') do
     it { should be_installed }
   end

describe file('/etc/yum.conf') do
  its(:content) { should match /metadata_expire=1800/ }
  its(:content) { should match /installonlypkgs=kernel kernel\*/ }
end

elsif ['debian', 'ubuntu'].include?(os[:family])

   describe file('/etc/apt/sources.list') do
      its(:md5sum) { should eq 'efc26bed90fce13e57440a76640baa1b' }
   end

   describe ppa('brightbox/ruby-ng') do
      it { should exist }
   end

   describe ppa('brightbox/ruby-ng') do
      it { should be_enabled }
   end

end