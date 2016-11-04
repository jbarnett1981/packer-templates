require 'spec_helper'

if os[:family] == 'redhat'

   describe file('/etc/sysconfig/network-scripts/ifcfg-eth0') do
      its(:content) { should match /PEERDNS=no/ }
   end
end

describe file('/etc/resolv.conf') do
  its(:content) { should match /search tsi.lan dev.tsi.lan tableaucorp.com db.tsi.lan test.tsi.lan/ }
  its(:content) { should match /nameserver 10.26.160.31/ }
  its(:content) { should match /nameserver 10.26.160.32/ }
end