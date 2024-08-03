# encoding: utf-8

module SPS
  class CreditTransfer < Message
    self.account_class = DebtorAccount
    self.transaction_class = CreditTransferTransaction
    self.xml_main_tag = 'CstmrCdtTrfInitn'
    self.known_schemas = [
      PAIN_001_001_03_CH_02
    ]

  private
    # Find groups of transactions which share the same values of some attributes
    def transaction_group(transaction)
      {
        requested_date:   transaction.requested_date,
        batch_booking:    transaction.batch_booking,
        service_level:    transaction.service_level,
        category_purpose: transaction.category_purpose,
        charge_bearer:    transaction.charge_bearer,
      }
    end

    def build_payment_informations(builder)
      # Build a PmtInf block for every group of transactions
      grouped_transactions.each do |group, transactions|
        # All transactions with the same requested_date are placed into the same PmtInf block
        builder.PmtInf do
          builder.PmtInfId(payment_information_identification(group))
          builder.PmtMtd('TRF')
          builder.BtchBookg(group[:batch_booking])
          builder.NbOfTxs(transactions.length)
          builder.CtrlSum('%.2f' % amount_total(transactions))
          builder.PmtTpInf do
            if group[:service_level]
              builder.SvcLvl do
                builder.Cd(group[:service_level])
              end
            end
            if group[:category_purpose]
              builder.CtgyPurp do
                builder.Cd(group[:category_purpose])
              end
            end
          end
          builder.ReqdExctnDt(group[:requested_date].iso8601)
          builder.Dbtr do
            builder.Nm(account.name)
          end
          builder.DbtrAcct do
            builder.Id do
              builder.IBAN(account.iban)
            end
          end
          builder.DbtrAgt do
            builder.FinInstnId do
              builder.BIC(account.bic)
            end
          end
          if group[:charge_bearer]
            builder.ChrgBr(group[:charge_bearer])
          end

          transactions.each do |transaction|
            build_transaction(builder, transaction)
          end
        end
      end
    end

    def build_transaction(builder, transaction)
      builder.CdtTrfTxInf do
        builder.PmtId do
          if transaction.instruction.present?
            builder.InstrId(transaction.instruction)
          end
          builder.EndToEndId(transaction.reference)
        end
        builder.Amt do
          builder.InstdAmt('%.2f' % transaction.amount, Ccy: transaction.currency)
        end
        if transaction.bic
          builder.CdtrAgt do
            builder.FinInstnId do
              builder.BIC(transaction.bic)
            end
          end
        end
        builder.Cdtr do
          builder.Nm(transaction.name)
          if transaction.creditor_address
            builder.PstlAdr do
              # Only set the fields that are actually provided.
              # StrtNm, BldgNb, PstCd, TwnNm provide a structured address
              # separated into its individual fields.
              # AdrLine provides the address in free format text.
              # Both are currently allowed and the actual preference depends on the bank.
              # Also the fields that are required legally may vary depending on the country
              # or change over time.
              if transaction.creditor_address.street_name
                builder.StrtNm transaction.creditor_address.street_name
              end

              if transaction.creditor_address.building_number
                builder.BldgNb transaction.creditor_address.building_number
              end

              if transaction.creditor_address.post_code
                builder.PstCd transaction.creditor_address.post_code
              end

              if transaction.creditor_address.town_name
                builder.TwnNm transaction.creditor_address.town_name
              end

              if transaction.creditor_address.country_code
                builder.Ctry transaction.creditor_address.country_code
              end

              if transaction.creditor_address.address_line1
                builder.AdrLine transaction.creditor_address.address_line1
              end

              if transaction.creditor_address.address_line2
                builder.AdrLine transaction.creditor_address.address_line2
              end
            end
          end
        end
        builder.CdtrAcct do
          builder.Id do
            builder.IBAN(transaction.iban)
          end
        end
        if transaction.remittance_information || transaction.structured_remittance_information
          builder.RmtInf do
            if transaction.remittance_information
              builder.Ustrd(transaction.remittance_information)
            end

            if transaction.structured_remittance_information
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
  end
end
