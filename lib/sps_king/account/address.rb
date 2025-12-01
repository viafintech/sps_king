# encoding: utf-8

module SPS
  class Address

    include ActiveModel::Validations
    extend Converter

    attr_accessor :street_name,
                  :department,
                  :sub_department,
                  :building_number,
                  :building_name,
                  :floor,
                  :post_box,
                  :room,
                  :post_code,
                  :town_name,
                  :town_location_name,
                  :district_name,
                  :country_subdivision,
                  :country_code,
                  :address_line1,
                  :address_line2

    convert :street_name,         to: :text
    convert :department,          to: :text
    convert :sub_department,      to: :text
    convert :building_number,     to: :text
    convert :building_name,       to: :text
    convert :floor,               to: :text
    convert :post_box,            to: :text
    convert :room,                to: :text
    convert :post_code,           to: :text
    convert :town_name,           to: :text
    convert :town_location_name,  to: :text
    convert :district_name,       to: :text
    convert :country_subdivision, to: :text
    convert :country_code,        to: :text
    convert :address_line1,       to: :text
    convert :address_line2,       to: :text

    validates :street_name,     length: { maximum: 70 }
    validates :building_number, length: { maximum: 16 }
    validates :building_name,   length: { maximum: 35 }
    validates :floor,           length: { maximum: 70 }
    validates :post_box,        length: { maximum: 16 }
    validates :room,            length: { maximum: 70 }
    validates :post_code,       length: { maximum: 16 }
    validates :town_name,       length: { maximum: 35 }
    validates :country_subdivision, length: { maximum: 35 }
    validates :country_code,
              presence: true,
              format:   { with: /\A[A-Z]{2}\z/ }
    validates :address_line1,   length: { maximum: 70 }
    validates :address_line2,   length: { maximum: 70 }
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
