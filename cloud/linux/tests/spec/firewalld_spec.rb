require 'spec_helper'

describe package('firewalld') do
  it { should be_installed }
end

describe service('firewalld') do
  it { should_not be_enabled   }
  it { should_not be_running   }
end

