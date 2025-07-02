# encoding: utf-8
require 'spec_helper'

describe SPS::Address do
  let(:country_code) { 'CH' }
  let(:street_name) { 'Mustergasse' }
  let(:building_number) { '123' }
  let(:post_code) { '12345' }
  let(:town_name) { 'Musterstadt' }
  let(:address_line1) { "#{street_name} #{building_number}" }
  let(:address_line2) { "#{post_code} #{town_name}" }
  let(:subject_valid) do
    described_class.new(country_code:,
                        address_line2:)
  end
  let(:subject_too_long) do
    described_class.new(country_code:,
                        address_line1: 'X' * 71,
                        address_line2: 'X' * 71)
  end

  it 'should validate country_code format' do
    subject_valid.country_code = 'ch'
    expect(subject_valid).not_to be_valid
    expect(subject_valid.errors.details).to include(country_code: [{ error: :invalid, value: "ch" }])
  end

  context 'when using address_line1 and address_line2' do
    it 'should initialize a new address in line mode' do
      expect(subject_valid).to be_valid
    end

    it 'validates address_line1 and address_line2 length' do
      expect(subject_too_long).not_to be_valid
      expect(subject_too_long.errors.details).to include(
        address_line1: [{ error: :too_long, count: 70 }],
        address_line2: [{ error: :too_long, count: 70 }]
      )
    end
  end

  context 'when using separate attributes' do
    let(:subject_valid) do
      described_class.new(country_code:,
                          town_name:)
    end
    let(:subject_too_long) do
      described_class.new(country_code:,
                          street_name: 'X' * 71,
                          building_number: 'X' * 17,
                          post_code: 'X' * 17,
                          town_name: 'X' * 36)
    end

    it 'should initialize a new address in separate mode' do
      expect(subject_valid).to be_valid
    end

    it 'validates street_name, building_number, post_code, and town_name length' do
      expect(subject_too_long).not_to be_valid
      expect(subject_too_long.errors.details).to include(
        street_name: [{ error: :too_long, count: 70 }],
        post_code: [{ error: :too_long, count: 16 }],
        town_name: [{ error: :too_long, count: 35 }]
      )
    end
  end
end
