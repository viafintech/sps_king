# encoding: utf-8

module SPS
  class Address

    include ActiveModel::Validations
    extend Converter

    attr_accessor :schema_version

    attr_accessor :street_name,
                  :building_number,
                  :post_code,
                  :town_name,
                  :country_code,
                  :address_line1,
                  :address_line2,
                  :department,
                  :sub_department,
                  :building_name,
                  :floor,
                  :post_box,
                  :room,
                  :town_location_name,
                  :district_name,
                  :country_subdivision,
                  :address_line1,
                  :address_lne2

    convert :department,         to: :text
    convert :sub_department,     to: :text
    convert :street_name,        to: :text
    convert :building_number,    to: :text
    convert :building_name,      to: :text
    convert :floor,              to: :text
    convert :post_box,           to: :text
    convert :room,               to: :text
    convert :post_code,          to: :text
    convert :town_name,          to: :text
    convert :town_location_name, to: :text
    convert :district_name,      to: :text
    convert :country_subdivision,to: :text
    convert :country_code,       to: :text
    convert :address_line1,      to: :text
    convert :address_line2,      to: :text

    validates :street_name,     length: { maximum: 70 }
    validates :building_number, length: { maximum: 16 }
    validates :building_name,   length: { maximum: 35 }
    validates :floor,           length: { maximum: 70 }
    validates :post_box,        length: { maximum: 16 }
    validates :room,            length: { maximum: 70 }
    validates :post_code,       length: { maximum: 16 }
    validates :town_name,       length: { maximum: 35 }
    validates :country_code,    presence: true, format: { with: /\A[A-Z]{2}\z/ }
    validates :address_line1,   length: { maximum: 70 }
    validates :address_line2,   length: { maximum: 70 }
    validate :address_with_version


    def initialize(attributes = {})
      @version = attributes.delete(:version) || :V3
      attributes.each do |name, value|
        public_send("#{name}=", value)
      end
    end

    private

      def address_line2_blank?
        address_line2.blank?
      end

      def each_address_line_max70
        Array(address_lines).each_with_index do |line, i|
          if line.to_s.length > 70
            errors.add(:address_lines, "AdrLine[#{i}] exceeds 70 characters")
          end
        end
      end

      def address_with_version
        if @version == :V3
          verify_v3_address
        else
          verify_v9_address
        end
      end

      def verify_v3_address
        errors.add(:address_line2, :blank) if address_line2.blank? && town_name.blank? 
        errors.add(:town_name, :blank) if town_name.blank? && address_line2.blank?
      end

      def verify_v9_address
        errors.add(:town_name, :blank) if town_name.blank?
      end

  end
end
