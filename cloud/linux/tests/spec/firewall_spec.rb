require 'spec_helper'

if os[:family] == 'redhat'

   describe package('firewalld') do
     it { should be_installed }
   end

   describe service('firewalld') do
     it { should_not be_enabled   }
     it { should_not be_running   }
   end

elsif ['debian', 'ubuntu'].include?(os[:family])

   describe package('ufw') do
     it { should be_installed }
   end
   describe service('ufw') do
     describe command('ufw status 2>&1') do
       its(:stdout) { should match(/Status: inactive/) }
     end
   end
end