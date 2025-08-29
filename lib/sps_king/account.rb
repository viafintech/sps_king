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

    def schema_version
      ( @schema_version || :V3 ).to_sym
    end

    def initialize(attributes = {})
      attributes.each do |name, value|
        public_send("#{name}=", value)
      end
    end

  end
end
