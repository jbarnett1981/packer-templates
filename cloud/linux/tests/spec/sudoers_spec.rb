require 'spec_helper'

describe file('/etc/sudoers') do
  its(:content) { should match /Defaults    !requiretty/ }
end