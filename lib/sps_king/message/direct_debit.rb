# encoding: utf-8

module SPS
  class DirectDebit < Message

    self.account_class = CreditorAccount
    self.transaction_class = DirectDebitTransaction
    self.xml_main_tag = 'CstmrDrctDbtInitn'
    self.known_schemas = {
      pain_008_001_02_ch_03: PAIN_008_001_02_CH_03,
      pain_001_001_09_ch_03: PAIN_001_001_09_CH_03
    }

    validate do |record|
      if record.transactions.map(&:local_instrument).uniq.size > 1
        errors.add(
          :base,
          'different local_instruments (e.g. LSV+, BDD) must not be mixed in one message!'
        )
      end
    end

    private

      # Find groups of transactions which share the same values of some attributes
      def transaction_group(transaction)
        {
          requested_date:   transaction.requested_date,
          service_level:    transaction.service_level,
          local_instrument: transaction.local_instrument,
          account:          transaction.creditor_account || account
        }
      end

      def creditor_scheme_name(service_level)
        case service_level
        when 'CHDD' # PAIN_008_001_02_CH_03 only
          return 'CHDD'
        when 'CHTA' # PAIN_008_001_02_CH_03 only
          return 'CHLS'
        end
      end

      # For IBANs from Switzerland or Liechtenstein the clearing system member id can be retrieved
      # as the 5th to 9th digit of the IBAN, which is the local bank code.
      def clearing_system_member_id_from_iban(iban)
        return iban.to_s[4..8].sub(/^0*/, '')
      end

      def build_payment_informations(builder, schema_name = PAIN_008_001_02_CH_03)
        # Build a PmtInf block for every group of transactions
        grouped_transactions.each do |group, transactions|
          builder.PmtInf do
            builder.PmtInfId(payment_information_identification(group))
            builder.PmtMtd('DD')
            builder.PmtTpInf do
              builder.SvcLvl do
                builder.Prtry(group[:service_level])
              end
              builder.LclInstrm do
                builder.Prtry(group[:local_instrument])
              end
            end
            builder.ReqdColltnDt(group[:requested_date].iso8601)
            builder.Cdtr do
              builder.Nm(group[:account].name)
            end
            builder.CdtrAcct do
              builder.Id do
                builder.IBAN(group[:account].iban)
              end
            end
            builder.CdtrAgt do
              builder.FinInstnId do
                builder.ClrSysMmbId do
                  builder.MmbId(clearing_system_member_id_from_iban(group[:account].iban))
                end
                if group[:account].isr_participant_number
                  builder.Othr do
                    builder.Id(group[:account].isr_participant_number)
                  end
                end
              end
            end
            builder.CdtrSchmeId do
              builder.Id do
                builder.PrvtId do
                  builder.Othr do
                    builder.Id(group[:account].creditor_identifier)
                    builder.SchmeNm do
                      builder.Prtry(creditor_scheme_name(group[:service_level]))
                    end
                  end
                end
              end
            end

            transactions.each do |transaction|
              build_transaction(builder, transaction)
            end
          end
        end
      end

      def build_transaction(builder, transaction)
        builder.DrctDbtTxInf do
          builder.PmtId do
            builder.InstrId(transaction.instruction)
            builder.EndToEndId(transaction.reference)
          end
          builder.InstdAmt('%.2f' % transaction.amount, Ccy: transaction.currency)
          builder.DbtrAgt do
            builder.FinInstnId do
              builder.ClrSysMmbId do
                builder.MmbId(clearing_system_member_id_from_iban(transaction.iban))
              end
            end
          end
          builder.Dbtr do
            builder.Nm(transaction.name)
            if transaction.debtor_address
              builder.PstlAdr do
                # Only set the fields that are actually provided.
                # StrtNm, BldgNb, PstCd, TwnNm provide a structured address
                # separated into its individual fields.
                # AdrLine provides the address in free format text.
                # Both are currently allowed and the actual preference depends on the bank.
                # Also the fields that are required legally may vary depending on the country
                # or change over time.
                if transaction.debtor_address.street_name
                  builder.StrtNm transaction.debtor_address.street_name
                end

                if transaction.debtor_address.post_code
                  builder.PstCd transaction.debtor_address.post_code
                end

                if transaction.debtor_address.town_name
                  builder.TwnNm transaction.debtor_address.town_name
                end

                if transaction.debtor_address.country_code
                  builder.Ctry transaction.debtor_address.country_code
                end

                if transaction.debtor_address.address_line1
                  builder.AdrLine transaction.debtor_address.address_line1
                end

                if transaction.debtor_address.address_line2
                  builder.AdrLine transaction.debtor_address.address_line2
                end
              end
            end
          end
          builder.DbtrAcct do
            builder.Id do
              builder.IBAN(transaction.iban)
            end
          end
          builder.RmtInf do
            if transaction.remittance_information
              builder.Ustrd(transaction.remittance_information)
            end

            builder.Strd do
              builder.CdtrRefInf do
                builder.Tp do
                  builder.CdOrPrtry do
                    builder.Prtry(transaction.structured_remittance_information.proprietary)
                  end
                end
                builder.Ref(transaction.structured_remittance_information.reference)
              end
            end
          end
        end
      end

  end
end
