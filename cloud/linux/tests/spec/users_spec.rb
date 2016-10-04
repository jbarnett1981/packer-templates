require 'spec_helper'

describe user('it') do
  it { should exist }
end

describe user('devlocal') do
  it { should exist }
end

describe user('it') do
  it { should belong_to_group 'it' }
end

describe user('devlocal') do
  it { should belong_to_group 'devlocal' }
end