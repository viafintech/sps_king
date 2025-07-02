# encoding: utf-8
module SPS
  class Address
    include ActiveModel::Validations
    extend Converter

    attr_accessor :street_name,
                  :building_number,
                  :post_code,
                  :town_name,
                  :country_code,
                  :address_line1,
                  :address_line2

    convert :street_name,     to: :text
    convert :building_number, to: :text
    convert :post_code,       to: :text
    convert :town_name,       to: :text
    convert :country_code,    to: :text
    convert :address_line1,   to: :text
    convert :address_line2,   to: :text

    validates :street_name,     length: { maximum: 70 }
    validates :building_number, length: { maximum: 16 }
    validates :post_code,       length: { maximum: 16 }
    validates :town_name,       length: { maximum: 35 }
    validates :address_line1,   length: { maximum: 70 }
    validates :address_line2,   length: { maximum: 70 }
    validates :country_code,    presence: true,
                                format: { with: /\A[A-Z]{2}\z/ }
    # either town_name or address_line2 must be present
    validates :address_line2,   presence: true, if: :town_name_blank?
    validates :town_name,       presence: true, if: :address_line2_blank?

    def initialize(attributes = {})
      attributes.each do |name, value|
        public_send("#{name}=", value)
      end
    end

    private

    def town_name_blank?
      town_name.blank?
    end

    def address_line2_blank?
      address_line2.blank?
    end
  end
end
