# encoding: utf-8

require 'spec_helper'

describe SPS::StructuredRemittanceInformation do
  describe :new do
    it 'should not accept unknown keys' do
      expect {
        SPS::StructuredRemittanceInformation.new foo: 'bar'
      }.to raise_error(NoMethodError)
    end
  end

  describe :proprietary do
    it 'should accept valid value' do
      expect(SPS::StructuredRemittanceInformation).to accept('ESR', 'IPI', 'QRR', for: :proprietary)
    end

    it 'should not accept invalid value' do
      expect(SPS::StructuredRemittanceInformation).not_to accept(
                                                            nil,
                                                            'something_else',
                                                            for: :proprietary
                                                          )
    end
  end

  describe :reference do
    it 'should accept valid value' do
      expect(SPS::StructuredRemittanceInformation).to accept('a' * 35, for: :reference)
    end

    it 'should not accept invalid value' do
      expect(SPS::StructuredRemittanceInformation).not_to accept('', 'a' * 36, for: :reference)
    end
  end
end
