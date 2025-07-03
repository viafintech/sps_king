# encoding: utf-8

module SPS
  module Converter

    def convert(*attributes, options)
      include InstanceMethods

      method_name = "convert_#{options[:to]}"
      unless InstanceMethods.method_defined?(method_name)
        raise ArgumentError.new("Converter '#{options[:to]}' does not exist!")
      end

      attributes.each do |attribute|
        define_method "#{attribute}=" do |value|
          instance_variable_set("@#{attribute}", send(method_name, value))
        end
      end
    end

    module InstanceMethods

      def convert_text(value)
        return unless value

        value.to_s.
          # Replace some special characters described as "Best practices" in Chapter 6.2 of this document:
          # http://www.europeanpaymentscouncil.eu/index.cfm/knowledge-bank/epc-documents/sepa-requirements-for-an-extended-character-set-unicode-subset-best-practices/
          gsub('€', 'E')
          .gsub('@', '(at)')
          .gsub('_', '-').

          # Replace linebreaks by spaces
          gsub(/\n+/, ' ').

          # Remove all invalid characters
          gsub(/[^a-zA-Z0-9ÄÖÜäöüß&*$%\ \'\:\?\,\-\(\+\.\)\/]/, '').

          # Remove leading and trailing spaces
          strip
      end

      # @param [BigDecimal|Integer|Float|String|nil] value the value to convert
      # @return [BigDecimal|nil] the converted value or nil if the conversion failed
      def convert_decimal(value)
        val = begin
          BigDecimal(value.to_s)
        rescue ArgumentError
          nil
        end
        val.round(2) if val&.finite? && val > 0
      end

    end

  end
end
