require 'spec_helper'

describe file('/etc/sudoers.d/tableau-devit') do
  its(:md5sum) { should eq '7b256f53fe2bf46e5d1f60d1e641450c' }
end

describe file('/etc/sudoers.d/tableau-devit') do
  it { should be_mode 644 }
end