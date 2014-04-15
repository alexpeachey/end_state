require 'spec_helper'

describe EndState do
  it 'should have a version number' do
    EndState::VERSION.should_not be_nil
  end

  it 'should do something useful' do
    false.should eq(true)
  end
end
