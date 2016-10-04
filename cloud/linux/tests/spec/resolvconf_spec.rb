require 'spec_helper'

describe file('/etc/resolv.conf') do
  its(:content) { should match /search tsi.lan dev.tsi.lan/ }
  its(:content) { should match /nameserver 10.26.160.31/ }
  its(:content) { should match /nameserver 10.26.160.32/ }
end
