# encoding: utf-8

require 'spec_helper'

describe SPS::Transaction do
  describe :new do
    it 'should have default for reference' do
      expect(SPS::Transaction.new.reference).to eq('NOTPROVIDED')
    end

    it 'should have default for requested_date' do
      expect(SPS::Transaction.new.requested_date).to eq(Date.new(1999, 1, 1))
    end

    it 'should have default for batch_booking' do
      expect(SPS::Transaction.new.batch_booking).to eq(true)
    end
  end

  context 'Name' do
    it 'should accept valid value' do
      expect(SPS::Transaction).to accept(
                                    'Manfred Mustermann III.',
                                    'Zahlemann & Söhne GbR',
                                    'X' * 70,
                                    for: :name
                                  )
    end

    it 'should not accept invalid value' do
      expect(SPS::Transaction).not_to accept(nil, '', 'X' * 71, for: :name)
    end
  end

  context 'Adress' do
    context 'with address_line' do
      it 'should accept valid value' do
        expect(SPS::Transaction).to accept(
                                      SPS::DebtorAddress.new(
                                        country_code:  "CH",
                                        address_line1: "Musterstrasse 123",
                                        address_line2: "1234 Musterstadt"
                                      ),
                                      for: :debtor_address
                                    )
      end

      it 'should accept valid value' do
        expect(SPS::Transaction).to accept(
                                      SPS::CreditorAddress.new(
                                        country_code:  "CH",
                                        address_line1: "Musterstrasse 123",
                                        address_line2: "1234 Musterstadt"
                                      ),
                                      for: :creditor_address
                                    )
      end
    end

    context 'with individual address fields' do
      it 'should accept valid value' do
        expect(SPS::Transaction).to accept(
                                      SPS::DebtorAddress.new(
                                        country_code: "CH",
                                        street_name:  'Mustergasse',
                                        post_code:    '1234',
                                        town_name:    'Musterstadt'
                                      ),
                                      for: :debtor_address
                                    )
      end

      it 'should accept valid value' do
        expect(SPS::Transaction).to accept(
                                      SPS::CreditorAddress.new(
                                        country_code:    "CH",
                                        street_name:     'Mustergasse',
                                        building_number: '123',
                                        post_code:       '1234',
                                        town_name:       'Musterstadt'
                                      ),
                                      for: :creditor_address
                                    )
      end
    end

    it 'should not accept invalid value' do
      expect(SPS::Transaction).not_to accept('', {}, for: :name)
    end
  end

  context 'IBAN' do
    it 'should accept valid value' do
      expect(SPS::Transaction).to accept(
                                    'DE21500500009876543210',
                                    'PL61109010140000071219812874',
                                    for: :iban
                                  )
    end

    it 'should not accept invalid value' do
      expect(SPS::Transaction).not_to accept(nil, '', 'invalid', for: :iban)
    end
  end

  context 'BIC' do
    it 'should accept valid value' do
      expect(SPS::Transaction).to accept('DEUTDEFF', 'DEUTDEFF500', 'SPUEDE2UXXX', for: :bic)
    end

    it 'should not accept invalid value' do
      expect(SPS::Transaction).not_to accept('', 'invalid', for: :bic)
    end
  end

  context 'Amount' do
    it 'should accept valid value' do
      expect(SPS::Transaction).to accept(
                                    0.01,
                                    1,
                                    100,
                                    100.00,
                                    99.99,
                                    1234567890.12,
                                    BigDecimal('10'),
                                    '42',
                                    '42.51',
                                    '42.512',
                                    1.23456,
                                    for: :amount
                                  )
    end

    it 'should not accept invalid value' do
      expect(SPS::Transaction).not_to accept(nil, 0, -3, 'xz', for: :amount)
    end
  end

  context 'Reference' do
    it 'should accept valid value' do
      expect(SPS::Transaction).to accept(nil, 'ABC-1234/78.0', 'X' * 35, for: :reference)
    end

    it 'should not accept invalid value' do
      expect(SPS::Transaction).not_to accept('', 'X' * 36, for: :reference)
    end
  end

  context 'Remittance information' do
    it 'should allow valid value' do
      expect(SPS::Transaction).to accept(nil, 'Bonus', 'X' * 140, for: :remittance_information)
    end

    it 'should not allow invalid value' do
      expect(SPS::Transaction).not_to accept('', 'X' * 141, for: :remittance_information)
    end
  end

  context 'Currency' do
    it 'should allow valid values' do
      expect(SPS::Transaction).to accept('EUR', 'CHF', 'SEK', for: :currency)
    end

    it 'should not allow invalid values' do
      expect(SPS::Transaction).not_to accept('', 'EURO', 'ABCDEF', for: :currency)
    end
  end
end
