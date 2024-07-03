# encoding: utf-8
require 'spec_helper'

describe SPS::CreditTransferTransaction do
  describe :initialize do
    it 'should initialize a valid transaction' do
      expect(
        SPS::CreditTransferTransaction.new(
          name:                   'Contoso AG',
          iban:                   'CH5481230000001998736',
          bic:                    'RAIFCH22',
          amount:                 102.50,
          reference:              'XYZ-1234/123',
          remittance_information: 'Rechnung 123 vom 22.08.2013',
        )
      ).to be_valid
    end
  end

  describe :schema_compatible? do
    context 'for pain.001.001.03.ch.02' do
      it 'should succeed for valid attributes' do
        expect(SPS::CreditTransferTransaction.new(bic: 'RAIFCH22', currency: 'CHF'))
          .to be_schema_compatible('pain.001.001.03.ch.02')
      end

      it 'should fail for invalid attributes' do
        expect(SPS::CreditTransferTransaction.new(bic: nil))
          .not_to be_schema_compatible('pain.001.001.03.ch.02')
      end
    end
  end

  context 'Requested date' do
    it 'should allow valid value' do
      expect(SPS::CreditTransferTransaction).to accept(nil, Date.new(1999, 1, 1), Date.today, Date.today.next, Date.today + 2, for: :requested_date)
    end

    it 'should not allow invalid value' do
      expect(SPS::CreditTransferTransaction).not_to accept(Date.new(1995,12,21), Date.today - 1, for: :requested_date)
    end
  end

  context 'Category Purpose' do
    it 'should allow valid value' do
      expect(SPS::CreditTransferTransaction).to accept(nil, 'SALA', 'X' * 4, for: :category_purpose)
    end

    it 'should not allow invalid value' do
      expect(SPS::CreditTransferTransaction).not_to accept('', 'X' * 5, for: :category_purpose)
    end
  end

  context 'Charge Bearer' do
    it 'should allow valid value' do
      expect(SPS::CreditTransferTransaction)
        .to accept(nil, 'DEBT', 'CRED', 'SHAR', 'SLEV', for: :charge_bearer)
    end

    it 'should not allow invalid value' do
      expect(SPS::CreditTransferTransaction)
        .not_to accept('', 'X' * 5, 'X' * 4, for: :charge_bearer)
    end
  end
end
