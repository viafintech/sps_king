# encoding: utf-8

require 'spec_helper'

describe SPS::IBANValidator do
  class Validatable

    include ActiveModel::Model
    attr_accessor :iban, :iban_the_terrible

    validates_with SPS::IBANValidator, message: "%{value} seems wrong"
    validates_with SPS::IBANValidator, field_name: :iban_the_terrible

  end

  it 'should accept valid IBAN' do
    expect(Validatable)
      .to accept(
            'DE21500500009876543210',
            'DE87200500001234567890',
            for: [:iban, :iban_the_terrible]
          )
  end

  it 'should not accept an invalid IBAN' do
    expect(Validatable).not_to accept(
                                 '',
                                 'xxx', # Oviously no IBAN
                                 'DE22500500009876543210',      # wrong checksum
                                 'DE2150050000987654321',       # too short
                                 'de87200500001234567890',      # downcase characters
                                 'DE87 2005 0000 1234 5678 90', # spaces included
                                 for: [:iban, :iban_the_terrible]
                               )
  end

  it "should customize error message" do
    v = Validatable.new(:iban => 'xxx')
    v.valid?
    expect(v.errors[:iban]).to eq(['xxx seems wrong'])
  end
end

describe SPS::BICValidator do
  class Validatable

    include ActiveModel::Model
    attr_accessor :bic, :custom_bic

    validates_with SPS::BICValidator, message: "%{value} seems wrong"
    validates_with SPS::BICValidator, field_name: :custom_bic

  end

  it 'should accept valid BICs' do
    expect(Validatable).to accept('DEUTDEDBDUE', 'DUSSDEDDXXX', for: [:bic, :custom_bic])
  end

  it 'should not accept an invalid BIC' do
    expect(Validatable)
      .not_to accept('', 'GENODE61HR', 'DEUTDEDBDUEDEUTDEDBDUE', for: [:bic, :custom_bic])
  end

  it "should customize error message" do
    v = Validatable.new(:bic => 'xxx')
    v.valid?
    expect(v.errors[:bic]).to eq(['xxx seems wrong'])
  end
end

describe SPS::CreditorIdentifierValidator do
  class Validatable

    include ActiveModel::Model
    attr_accessor :creditor_identifier, :crid

    validates_with SPS::CreditorIdentifierValidator, message: "%{value} seems wrong"
    validates_with SPS::CreditorIdentifierValidator, field_name: :crid

  end

  it 'should accept valid creditor_identifier' do
    expect(Validatable).to accept(
                             'DE98ZZZ09999999999',
                             'AT12ZZZ00000000001',
                             'FR12ZZZ123456',
                             'NL97ZZZ123456780001',
                             'ABC1W',
                             for: [:creditor_identifier, :crid]
                           )
  end

  it 'should not accept an invalid creditor_identifier' do
    expect(Validatable).not_to accept(
                                 '',
                                 'xxx',
                                 'DE98ZZZ099999999990',
                                 for: [:creditor_identifier, :crid]
                               )
  end

  it "should customize error message" do
    v = Validatable.new(:creditor_identifier => 'xxx')
    v.valid?
    expect(v.errors[:creditor_identifier]).to eq(['xxx seems wrong'])
  end
end
