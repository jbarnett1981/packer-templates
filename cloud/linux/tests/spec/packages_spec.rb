require 'spec_helper'

if os[:family] == 'redhat'

   describe package('net-tools') do
     it { should be_installed }
   end

   describe package('nfs-utils') do
     it { should be_installed }
   end

   describe package('samba-client') do
     it { should be_installed }
   end

   describe package('samba-common') do
     it { should be_installed }
   end

   describe package('redhat-lsb-core') do
     it { should be_installed }
   end

   describe package('bind-utils') do
     it { should be_installed }
   end

elsif ['debian', 'ubuntu'].include?(os[:family])

   describe package('lsb-release') do
     it { should be_installed }
   end

   describe package('dnsutils') do
     it { should be_installed }
   end

end

describe package('git') do
  it { should be_installed }
end

describe package('cifs-utils') do
  it { should be_installed }
end

describe package('wget') do
  it { should be_installed }
end

describe package('perl') do
  it { should be_installed }
end

describe package('zip') do
  it { should be_installed }
end

describe package('tree') do
  it { should be_installed }
end