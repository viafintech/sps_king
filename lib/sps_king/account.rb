# encoding: utf-8

module SPS
  class Account

    include ActiveModel::Validations
    extend Converter

    attr_accessor :name,
                  :iban,
                  :bic,
                  :schema_version

    convert :name, to: :text

    validates_length_of :name, within: 1..70
    validates_with BICValidator,
                   IBANValidator,
                   message: "%{value} is invalid"

    def schema_version( type )
      ( @schema_version || method(type).call  ).to_sym
    end

    def direct_debit_schema
      :pain_008_001_02_ch_03
    end

    def credit_transfers_schema
      :pain_001_001_03_ch_02
    end


    def initialize(attributes = {})
      attributes.each do |name, value|
        public_send("#{name}=", value)
      end
    end

  end
end
