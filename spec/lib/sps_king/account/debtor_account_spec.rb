# encoding: utf-8
require 'spec_helper'

describe SPS::DebtorAccount do
  it 'should initialize a new account' do
    expect(
      SPS::DebtorAccount.new(
        name: 'Gläubiger GmbH',
        bic:  'BANKDEFFXXX',
        iban: 'DE87200500001234567890'
      )
    ).to be_valid
  end
end
