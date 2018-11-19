# encoding: utf-8
module SPS
  class DirectDebitTransaction < Transaction
    SERVICE_LEVELS = %w(CHDD CHTA)

    LOCAL_INSTRUMENTS_FOR_SERVICE_LEVELS = {
      'CHDD' => %w(DDCOR1 DDB2B),
      'CHTA' => %w(LSV+ BDD)
    }

    attr_accessor :service_level,
                  :local_instrument,
                  :creditor_account,
                  :debtor_address

    validates_format_of :iban, with: /\A(CH|LI)/

    validates_presence_of :instruction,
                          :structured_remittance_information

    validates_inclusion_of :service_level, in: SERVICE_LEVELS, allow_nil: true
    validate { |t| t.validate_local_instrument }
    validate { |t| t.validate_requested_date_after(Date.today.next) }

    validate do |t|
      if creditor_account
        errors.add(:creditor_account, 'is not correct') unless creditor_account.valid?
      end
    end

    def initialize(attributes = {})
      super
      self.service_level    ||= 'CHTA'
      self.local_instrument ||= 'LSV+'
    end

    def schema_compatible?(schema_name)
      case schema_name
      when PAIN_008_001_02_CH_03
        self.structured_remittance_information.present? &&
        self.structured_remittance_information.valid?
      end
    end

    def validate_local_instrument
      if SERVICE_LEVELS.include?(self.service_level)
        allowed_local_instruments = LOCAL_INSTRUMENTS_FOR_SERVICE_LEVELS[self.service_level]

        if !allowed_local_instruments.include?(self.local_instrument)
          errors.add(
            :local_instrument,
            "is not correct. Must be one of #{allowed_local_instruments.join(', ')}"
          )
        end
      end
    end
  end
end
