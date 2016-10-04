require 'spec_helper'

describe file('/etc/sudoers.d/tableau-devit') do
  its(:md5sum) { should eq '43cde4be29367417e42e5e4bff8cb7cb' }
end

describe file('/etc/sudoers.d/tableau-devit') do
  it { should be_mode 644 }
end