require 'spec_helper'

describe package('tzdata') do
  it { should be_installed }
end

if os[:family] == 'redhat'

   describe command("timedatectl status | grep -i zone | awk '{print $3}'") do
     its(:stdout) { should match 'America/Los_Angeles' }
   end
end

if ['debian', 'ubuntu'].include?(os[:family])
   if os[:release] == '16.04'
      describe command("timedatectl status | grep -i zone | awk '{print $3}'") do
         its(:stdout) { should match 'America/Los_Angeles' }
      end
   else
      describe command("timedatectl status | grep -i zone | awk '{print $2}'") do
         its(:stdout) { should match 'America/Los_Angeles' }
      end
   end
end