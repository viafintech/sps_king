# encoding: utf-8

require 'spec_helper'

describe SPS::DirectDebitTransaction do
  let(:structured_remittance_information) do
    SPS::StructuredRemittanceInformation.new(
      proprietary: 'ESR',
      reference:   '609323234234234353453423423'
    )
  end

  describe :initialize do
    it 'should create a valid transaction' do
      expect(
        SPS::DirectDebitTransaction.new(
          name:                              'Zahlemann & Söhne Gbr',
          iban:                              'CH7081232000001998736',
          amount:                            39.99,
          reference:                         'XYZ-1234/123',
          instruction:                       '123',
          remittance_information:            'Vielen Dank für Ihren Einkauf!',
          structured_remittance_information: structured_remittance_information
        )
      ).to be_valid
    end
  end

  describe :schema_compatible? do
    context 'for pain.008.001.02.ch.03' do
      it 'should succeed for valid attributes' do
        expect(
          SPS::DirectDebitTransaction.new(
            structured_remittance_information: structured_remittance_information
          )
        ).to be_schema_compatible('pain.008.001.02.ch.03')
      end

      it 'should fail for invalid attributes' do
        expect(SPS::DirectDebitTransaction.new())
          .not_to be_schema_compatible('pain.008.001.02.ch.03')
      end
    end
  end

  context 'Requested date' do
    it 'should allow valid value' do
      expect(SPS::DirectDebitTransaction)
        .to accept(nil, Date.new(1999, 1, 1), Date.today.next, Date.today + 2, for: :requested_date)
    end

    it 'should not allow invalid value' do
      expect(SPS::DirectDebitTransaction)
        .not_to accept(Date.new(1995, 12, 21), Date.today - 1, Date.today, for: :requested_date)
    end
  end
end
