# encoding: utf-8
module SPS
  class CreditTransferTransaction < Transaction
    attr_accessor :service_level,
                  :creditor_address,
                  :category_purpose,
                  :charge_bearer

    CHARGE_BEARERS = ['DEBT', 'CRED', 'SHAR', 'SLEV'].freeze

    validates_length_of :category_purpose, within: 1..4, allow_nil: true

    validates :charge_bearer, inclusion: CHARGE_BEARERS, allow_nil: true

    validate { |t| t.validate_requested_date_after(Date.today) }

    def schema_compatible?(schema_name)
      case schema_name
      when PAIN_001_001_03_CH_02
        !self.bic.nil?
      end
    end
  end
end
