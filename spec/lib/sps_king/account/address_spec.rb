# encoding: utf-8

require 'spec_helper'

describe SPS::Address do
  let(:country_code)    { 'CH' }
  let(:street_name)     { 'Mustergasse' }
  let(:building_number) { '123' }
  let(:post_code)       { '12345' }
  let(:town_name)       { 'Musterstadt' }
  let(:address_line1)   { "#{street_name} #{building_number}" }
  let(:address_line2)   { "#{post_code} #{town_name}" }
  let(:subject_valid) do
    described_class.new(
      country_code:,
      address_line2:
    )
  end
  let(:subject_too_long) do
    described_class.new(
      country_code:,
      address_line1: 'X' * 71,
      address_line2: 'X' * 71,
    )
  end

  it 'should validate country_code format' do
    subject_valid.country_code = 'ch'
    expect(subject_valid).not_to be_valid
    expect(subject_valid.errors.details).to include(
                                              country_code: [
                                                {
                                                  error: :invalid,
                                                  value: "ch"
                                                }
                                              ]
                                            )
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
      described_class.new(
        country_code:,
        town_name:
      )
    end
    let(:subject_too_long) do
      described_class.new(
        country_code:,
        street_name:     'X' * 71,
        building_number: 'X' * 17,
        post_code:       'X' * 17,
        town_name:       'X' * 36,
      )
    end

    it 'should initialize a new address in separate mode' do
      expect(subject_valid).to be_valid
    end

    it 'validates street_name, building_number, post_code, and town_name length' do
      expect(subject_too_long).not_to be_valid
      expect(subject_too_long.errors.details)
        .to include(
              street_name: [{ error: :too_long, count: 70 }],
              post_code:   [{ error: :too_long, count: 16 }],
              town_name:   [{ error: :too_long, count: 35 }]
            )
    end
  end

  #
  # NEW SPECS FOR SCHEMA-SPECIFIC BEHAVIOR
  #
  context 'with schema-specific rules' do
    let(:schema_v3) { SPS::PAIN_001_001_03_CH_02 }
    let(:schema_v9) { SPS::PAIN_001_001_09_CH_03 }

    context 'hybrid mode (mixing line + structured fields)' do
      let(:hybrid_address) do
        described_class.new(
          country_code: 'CH',
          address_line1: 'Mustergasse 123',
          town_name: 'Musterstadt'
        )
      end

      it 'is valid in v9' do
        hybrid_address.schema_version = schema_v9
        expect(hybrid_address).to be_valid
      end
    end

    context 'structured mode' do
      let(:structured_address) do
        described_class.new(
          country_code: 'CH',
          street_name: 'Mustergasse',
          building_number: '12a',
          post_code: '1234',
          town_name: 'Musterstadt'
        )
      end

      it 'is valid in v3' do
        structured_address.schema_version = schema_v3
        expect(structured_address).to be_valid
      end

      it 'is valid in v9' do
        structured_address.schema_version = schema_v9
        expect(structured_address).to be_valid
      end
    end

    it 'is invalid in v3 without town_name and address_line2' do
      addr = described_class.new(country_code: 'CH')
      addr.schema_version = schema_v3
      expect(addr).not_to be_valid
      expect(addr.errors.details).to include(
      town_name:     [error: :blank],
      address_line2: [error: :blank]
    )
    end

    it 'is invalid in v9 without town_name' do
      addr = described_class.new(country_code: 'CH')
      addr.schema_version = schema_v9
      expect(addr).not_to be_valid
      expect(addr.errors.details).to include(
        town_name:     [error: :blank],
        address_line2: [error: :blank] # because our validator still enforces fallback
      )
    end

    it 'is invalid in v9 without country_code' do
      addr = described_class.new(town_name: 'Musterstadt')
      addr.schema_version = schema_v9
      expect(addr).not_to be_valid
      expect(addr.errors.details).to include(
        country_code: [
          { error: :blank },
          { error: :invalid, value: nil }
        ]
      )
    end

    context 'line mode' do
      let(:line_address) do
        described_class.new(
          country_code: 'CH',
          address_line1: 'Mustergasse 12a',
          address_line2: '1234 Musterstadt'
        )
      end

      it 'is valid in v3' do
        line_address.schema_version = schema_v3
        expect(line_address).to be_valid
      end

      it 'is valid in v9' do
        line_address.schema_version = schema_v9
        expect(line_address).to be_valid
      end
    end
  end
end
