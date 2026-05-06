# encoding: utf-8

module SPS
  class DebtorAccount < Account

    extend Converter

    attr_accessor :proprietary

    ### Proprietary values
    # NOA No Advice
    # SIA Single Advice
    # CND Collective Advice No Details
    # CWD Collective Advice With Details
    PROPRIETARY_VALUES = %w[NOA SIA CND CWD].freeze

    validates :proprietary, inclusion: PROPRIETARY_VALUES, allow_nil: true

    convert :proprietary, to: :text
  end
end
