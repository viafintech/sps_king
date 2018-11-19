require 'spec_helper'

describe 'Credit Transfer Initiation' do
  it "should validate example file" do
    expect(File.read('spec/examples/pain.001.001.03.ch.02.xml'))
      .to validate_against('pain.001.001.03.ch.02.xsd')
  end

  it 'should not validate dummy string' do
    expect('foo').not_to validate_against('pain.001.001.03.ch.02.xsd')
  end
end

describe 'Direct Debit Initiation' do
  it 'should validate example file' do
    expect(File.read('spec/examples/pain.008.001.02.ch.03.xml'))
      .to validate_against('pain.008.001.02.ch.03.xsd')
  end

  it 'should not validate dummy string' do
    expect('foo').not_to validate_against('pain.008.001.02.ch.03.xsd')
  end
end
