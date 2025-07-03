# encoding: utf-8

require 'spec_helper'

describe SPS::DirectDebit do
  let(:message_id_regex) { /SPS-KING\/[0-9a-z_]{22}/ }

  let(:direct_debit) {
    SPS::DirectDebit.new(
      name:                'Gläubiger GmbH',
      iban:                'CH5481230000001998736',
      creditor_identifier: 'DE98ZZZ09999999999'
    )
  }

  describe :new do
    it 'should accept missing options' do
      expect {
        SPS::DirectDebit.new
      }.to_not raise_error
    end
  end

  describe :add_transaction do
    it 'should add valid transactions' do
      3.times do
        direct_debit.add_transaction(direct_debt_transaction)
      end

      expect(direct_debit.transactions.size).to eq(3)
    end

    it 'should fail for invalid transaction' do
      expect {
        direct_debit.add_transaction name: ''
      }.to raise_error(ArgumentError)
    end
  end

  describe :batch_id do
    it 'returns the id of the batch where the given transactions belongs to (1 batch)' do
      direct_debit.add_transaction(direct_debt_transaction(reference: "EXAMPLE REFERENCE"))

      expect(direct_debit.batch_id("EXAMPLE REFERENCE")).to match(/#{message_id_regex}\/1/)
    end

    it 'returns the id of the batch where the given transactions belongs to (2 batches)' do
      direct_debit.add_transaction(direct_debt_transaction(reference: "EXAMPLE REFERENCE 1"))
      direct_debit.add_transaction(
        direct_debt_transaction(
          reference:      "EXAMPLE REFERENCE 2",
          requested_date: Date.today.next.next
        )
      )
      direct_debit.add_transaction(direct_debt_transaction(reference: "EXAMPLE REFERENCE 3"))

      expect(direct_debit.batch_id("EXAMPLE REFERENCE 1")).to match(/#{message_id_regex}\/1/)
      expect(direct_debit.batch_id("EXAMPLE REFERENCE 2")).to match(/#{message_id_regex}\/2/)
      expect(direct_debit.batch_id("EXAMPLE REFERENCE 3")).to match(/#{message_id_regex}\/1/)
    end
  end

  describe :batches do
    it 'returns an array of batch ids in the sepa message' do
      direct_debit.add_transaction(direct_debt_transaction(reference: "EXAMPLE REFERENCE 1"))
      direct_debit.add_transaction(
        direct_debt_transaction(
          reference:      "EXAMPLE REFERENCE 2",
          requested_date: Date.today.next.next
        )
      )
      direct_debit.add_transaction(direct_debt_transaction(reference: "EXAMPLE REFERENCE 3"))

      expect(direct_debit.batches.size).to eq(2)
      expect(direct_debit.batches[0]).to match(/#{message_id_regex}\/[0-9]+/)
      expect(direct_debit.batches[1]).to match(/#{message_id_regex}\/[0-9]+/)
    end
  end

  describe :to_xml do
    context 'for invalid creditor' do
      it 'should fail' do
        expect {
          SPS::DirectDebit.new.to_xml
        }.to raise_error(SPS::Error)
      end
    end

    context 'setting debtor address with adrline' do
      subject do
        sdd = SPS::DirectDebit.new(
                name:                'Gläubiger GmbH',
                iban:                'CH7081232000001998736',
                creditor_identifier: 'ABC1W'
              )

        sda = SPS::DebtorAddress.new(
                country_code:  'CH',
                address_line1: 'Mustergasse 123',
                address_line2: '1234 Musterstadt'
              )

        sdd.add_transaction(
          name:                              'Zahlemann & Söhne GbR',
          iban:                              'CH9804835011062385295',
          amount:                            39.99,
          instruction:                       '12',
          reference:                         'XYZ/2013-08-ABO/12345',
          remittance_information:            'Unsere Rechnung vom 10.08.2013',
          debtor_address:                    sda,
          structured_remittance_information: structured_remittance_information
        )

        sdd
      end

      it 'should validate against pain.008.001.02.ch.03' do
        expect(subject.to_xml(SPS::PAIN_008_001_02_CH_03))
          .to validate_against('pain.008.001.02.ch.03.xsd')
      end
    end

    context 'setting debtor address with structured fields' do
      subject do
        sdd = SPS::DirectDebit.new(
                name:                'Gläubiger GmbH',
                iban:                'CH7081232000001998736',
                creditor_identifier: 'ABC1W'
              )

        sda = SPS::DebtorAddress.new(
                country_code: 'CH',
                street_name:  'Mustergasse 123',
                post_code:    '1234',
                town_name:    'Musterstadt'
              )

        sdd.add_transaction(
          name:                              'Zahlemann & Söhne GbR',
          iban:                              'CH9804835011062385295',
          amount:                            39.99,
          instruction:                       '12',
          reference:                         'XYZ/2013-08-ABO/12345',
          remittance_information:            'Unsere Rechnung vom 10.08.2013',
          debtor_address:                    sda,
          structured_remittance_information: structured_remittance_information
        )

        sdd
      end

      it 'should validate against pain.008.001.02.ch.03' do
        expect(subject.to_xml(SPS::PAIN_008_001_02_CH_03))
          .to validate_against('pain.008.001.02.ch.03.xsd')
      end
    end

    context 'for valid creditor' do
      context 'for swiss direct debits' do
        let(:creditor_iban) { 'CH7081232000001998736' }
        let(:debtior_iban)  { 'CH9804835011062385295' }

        let(:direct_debit) do
          sdd = SPS::DirectDebit.new(
                  name:                   'Muster AG',
                  isr_participant_number: '010001456',
                  iban:                   creditor_iban,
                  creditor_identifier:    'ABC1W'
                )

          sda = SPS::DebtorAddress.new(
                  country_code:  'CH',
                  address_line1: 'Mustergasse 123',
                  address_line2: '1234 Musterstadt'
                )

          sdd.add_transaction(
            {
              name:                              'HANS TESTER',
              iban:                              debtior_iban,
              currency:                          'CHF',
              amount:                            '100.0',
              remittance_information:            'According to invoice 4712',
              reference:                         'XYZ/2013-08-ABO/12345',
              service_level:                     service_level,
              local_instrument:                  local_instrument,
              requested_date:                    requested_date,
              instruction:                       23,
              debtor_address:                    sda,
              structured_remittance_information: SPS::StructuredRemittanceInformation.new(
                                                   proprietary: 'ESR',
                                                   reference:   '185744810000000000200800628'
                                                 )
            }.merge(additional_fields)
          )

          sdd
        end

        let(:service_level) { 'CHTA' }
        let(:local_instrument) { 'LSV+' }

        let(:additional_fields) { {} }

        let(:requested_date) { Date.today.next }

        context 'as xml' do
          subject do
            direct_debit.to_xml(SPS::PAIN_008_001_02_CH_03)
          end

          it 'should have creditor identifier' do
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/GrpHdr/InitgPty/Id/OrgId/Othr/Id', direct_debit.account.creditor_identifier
                               )
          end

          it 'should contain <PmtInfId>' do
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/PmtInf/PmtInfId',
                                 /#{message_id_regex}\/1/
                               )
          end

          it 'should contain <ReqdColltnDt>' do
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/PmtInf/ReqdColltnDt',
                                 requested_date.iso8601
                               )
          end

          it 'should contain <PmtMtd>' do
            expect(subject).to have_xml('//Document/CstmrDrctDbtInitn/PmtInf/PmtMtd', 'DD')
          end

          it 'should not contain <BtchBookg>' do
            expect(subject).not_to have_xml('//Document/CstmrDrctDbtInitn/PmtInf/BtchBookg')
          end

          it 'should not contain <NbOfTxs>' do
            expect(subject).not_to have_xml('//Document/CstmrDrctDbtInitn/PmtInf/NbOfTxs')
          end

          it 'should not contain <CtrlSum>' do
            expect(subject).not_to have_xml('//Document/CstmrDrctDbtInitn/PmtInf/CtrlSum')
          end

          it 'should contain <Cdtr>' do
            expect(subject).to have_xml('//Document/CstmrDrctDbtInitn/PmtInf/Cdtr/Nm', 'Muster AG')
          end

          it 'should contain <CdtrAcct>' do
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/PmtInf/CdtrAcct/Id/IBAN',
                                 'CH7081232000001998736'
                               )
          end

          it 'should contain <CdtrAgt>' do
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/PmtInf/CdtrAgt/FinInstnId/ClrSysMmbId/MmbId', '81232'
                               )
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/PmtInf/CdtrAgt/FinInstnId/Othr/Id', '010001456'
                               )
          end

          it 'should not contain <ChrgBr>' do
            expect(subject).not_to have_xml('//Document/CstmrDrctDbtInitn/PmtInf/ChrgBr')
          end

          context 'when service_level is CHTA' do
            it 'should contain <CdtrSchmeId>' do
              expect(subject).to have_xml(
                                   '//Document/CstmrDrctDbtInitn/PmtInf/CdtrSchmeId/Id/PrvtId/Othr/Id', direct_debit.account.creditor_identifier
                                 )
              expect(subject).to have_xml(
                                   '//Document/CstmrDrctDbtInitn/PmtInf/CdtrSchmeId/Id/PrvtId/Othr/SchmeNm/Prtry', 'CHLS'
                                 )
            end
          end

          context 'when service_level is CHDD' do
            let(:service_level) { 'CHDD' }
            let(:local_instrument) { 'DDCOR1' }

            it 'should contain <CdtrSchmeId>' do
              expect(subject).to have_xml(
                                   '//Document/CstmrDrctDbtInitn/PmtInf/CdtrSchmeId/Id/PrvtId/Othr/Id', direct_debit.account.creditor_identifier
                                 )
              expect(subject).to have_xml(
                                   '//Document/CstmrDrctDbtInitn/PmtInf/CdtrSchmeId/Id/PrvtId/Othr/SchmeNm/Prtry', 'CHDD'
                                 )
            end
          end

          it 'should contain <EndToEndId>' do
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/PmtInf/DrctDbtTxInf[1]/PmtId/EndToEndId', 'XYZ/2013-08-ABO/12345'
                               )
          end

          it 'should contain <InstdAmt>' do
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/PmtInf/DrctDbtTxInf[1]/InstdAmt', '100.00'
                               )
          end

          it 'should contain <DbtrAgt>' do
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/PmtInf/DrctDbtTxInf[1]/DbtrAgt/FinInstnId/ClrSysMmbId/MmbId', '4835'
                               )
          end

          it 'should contain <Dbtr>' do
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/PmtInf/DrctDbtTxInf[1]/Dbtr/Nm', 'HANS TESTER'
                               )
          end

          it 'should contain <DbtrAcct>' do
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/PmtInf/DrctDbtTxInf[1]/DbtrAcct/Id/IBAN', 'CH9804835011062385295'
                               )
          end

          it 'should contain <Ustrd>' do
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/PmtInf/DrctDbtTxInf[1]/RmtInf/Ustrd', 'According to invoice 4712'
                               )
          end

          it 'should contain <Strd>' do
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/PmtInf/DrctDbtTxInf[1]/RmtInf/Strd/CdtrRefInf/Tp/CdOrPrtry/Prtry', 'ESR'
                               )
            expect(subject).to have_xml(
                                 '//Document/CstmrDrctDbtInitn/PmtInf/DrctDbtTxInf[1]/RmtInf/Strd/CdtrRefInf/Ref', '185744810000000000200800628'
                               )
          end
        end

        context 'with service_level CHDD' do
          let(:service_level) { 'CHDD' }

          context 'with local_instrument DDCOR1' do
            let(:local_instrument) { 'DDCOR1' }

            it 'should validate against pain.008.001.02.ch.03' do
              expect(direct_debit.to_xml(SPS::PAIN_008_001_02_CH_03)).to validate_against('pain.008.001.02.ch.03.xsd')
            end
          end

          context 'with local_instrument DDB2B' do
            let(:local_instrument) { 'DDB2B' }

            it 'should validate against pain.008.001.02.ch.03' do
              expect(direct_debit.to_xml(SPS::PAIN_008_001_02_CH_03)).to validate_against('pain.008.001.02.ch.03.xsd')
            end
          end
        end

        context 'with service_level CHTA' do
          let(:service_level) { 'CHTA' }

          context 'with local_instrument LSV+' do
            let(:local_instrument) { 'LSV+' }

            it 'should validate against pain.008.001.02.ch.03' do
              expect(direct_debit.to_xml(SPS::PAIN_008_001_02_CH_03)).to validate_against('pain.008.001.02.ch.03.xsd')
            end
          end

          context 'with local_instrument BDD' do
            let(:local_instrument) { 'BDD' }

            it 'should validate against pain.008.001.02.ch.03' do
              expect(direct_debit.to_xml(SPS::PAIN_008_001_02_CH_03)).to validate_against('pain.008.001.02.ch.03.xsd')
            end
          end
        end

        context 'without structured_remittance_information' do
          it 'should not be schema compatible' do
            direct_debit.transactions.first.structured_remittance_information = nil

            expect {
              direct_debit.to_xml(SPS::PAIN_008_001_02_CH_03)
            }.to raise_error(SPS::Error, "Incompatible with schema pain.008.001.02.ch.03!")
          end
        end
      end

      context 'without requested_date given' do
        subject do
          sdd = direct_debit

          sdd.add_transaction(
            name:                              'Zahlemann & Söhne GbR',
            iban:                              'CH9804835011062385295',
            amount:                            39.99,
            instruction:                       '12',
            reference:                         'XYZ/2013-08-ABO/12345',
            remittance_information:            'Unsere Rechnung vom 10.08.2013',
            structured_remittance_information: structured_remittance_information
          )

          sdd.add_transaction(
            name:                              'Meier & Schulze oHG',
            iban:                              'CH7081232000001998736',
            amount:                            750.00,
            instruction:                       '34',
            reference:                         'XYZ/2013-08-ABO/6789',
            remittance_information:            'Vielen Dank für Ihren Einkauf!',
            structured_remittance_information: structured_remittance_information
          )

          sdd.to_xml
        end

        it 'should create valid XML file' do
          expect(subject).to validate_against('pain.008.001.02.ch.03.xsd')
        end

        it 'should contain <ReqdColltnDt>' do
          expect(subject).to have_xml(
                               '//Document/CstmrDrctDbtInitn/PmtInf/ReqdColltnDt',
                               Date.new(1999, 1, 1).iso8601
                             )
        end
      end

      context 'with different requested_date given' do
        subject do
          sdd = direct_debit

          sdd.add_transaction(direct_debt_transaction.merge requested_date: Date.today + 1)
          sdd.add_transaction(direct_debt_transaction.merge requested_date: Date.today + 2)
          sdd.add_transaction(direct_debt_transaction.merge requested_date: Date.today + 2)

          sdd.to_xml
        end

        it 'should contain two payment_informations with <ReqdColltnDt>' do
          expect(subject).to have_xml(
                               '//Document/CstmrDrctDbtInitn/PmtInf[1]/ReqdColltnDt',
                               (Date.today + 1).iso8601
                             )
          expect(subject).to have_xml(
                               '//Document/CstmrDrctDbtInitn/PmtInf[2]/ReqdColltnDt',
                               (Date.today + 2).iso8601
                             )

          expect(subject).not_to have_xml('//Document/CstmrDrctDbtInitn/PmtInf[3]')
        end

        it 'should contain two payment_informations with different <PmtInfId>' do
          expect(subject).to have_xml(
                               '//Document/CstmrDrctDbtInitn/PmtInf[1]/PmtInfId',
                               /#{message_id_regex}\/1/
                             )
          expect(subject).to have_xml(
                               '//Document/CstmrDrctDbtInitn/PmtInf[2]/PmtInfId',
                               /#{message_id_regex}\/2/
                             )
        end
      end

      context 'with different local_instrument given' do
        subject do
          sdd = direct_debit

          sdd.add_transaction(direct_debt_transaction.merge local_instrument: 'LSV+')
          sdd.add_transaction(direct_debt_transaction.merge local_instrument: 'BDD')

          sdd
        end

        it 'should have errors' do
          expect(subject.errors_on(:base).size).to eq(1)
        end

        it 'should raise error on XML generation' do
          expect {
            subject.to_xml
          }.to raise_error(SPS::Error)
        end
      end

      context 'with mismatching local_instrument given' do
        subject do
          sdd = direct_debit

          sdd.add_transaction(direct_debt_transaction.merge(local_instrument: 'DDCOR1'))

          sdd
        end

        it 'raises an ArgumentError' do
          expect {
            subject.add_transaction(direct_debt_transaction.merge(local_instrument: 'DDB2B'))
          }.to raise_error(
                 ArgumentError,
                 'Local instrument is not correct. Must be one of LSV+, BDD'
               )
        end
      end

      context 'with transactions containing different creditor_account' do
        subject do
          sdd = direct_debit

          sdd.add_transaction(direct_debt_transaction)
          sdd.add_transaction(
            direct_debt_transaction.merge(
              creditor_account: SPS::CreditorAccount.new(
                                  name:                'Creditor Inc.',
                                  iban:                'CH5604835012345678009',
                                  creditor_identifier: 'ABC1W'
                                )
            )
          )

          sdd.to_xml
        end

        it 'should contain two payment_informations with <Cdtr>' do
          expect(subject).to have_xml(
                               '//Document/CstmrDrctDbtInitn/PmtInf[1]/Cdtr/Nm',
                               'Gläubiger GmbH'
                             )
          expect(subject).to have_xml(
                               '//Document/CstmrDrctDbtInitn/PmtInf[2]/Cdtr/Nm',
                               'Creditor Inc.'
                             )
        end
      end

      context 'with large message identification' do
        subject do
          sct = direct_debit
          sct.message_identification = 'A' * 35
          sct.add_transaction(direct_debt_transaction.merge(instruction: '1234/ABC'))
          sct
        end

        it 'should fail as the payment identification becomes too large' do
          expect { subject.to_xml }.to raise_error(SPS::Error)
        end
      end
    end

    context 'with no encoding specified' do
      subject do
        sdd = direct_debit

        sdd.add_transaction(
          name:                              'Zahlemann & Söhne GbR',
          iban:                              'CH9804835011062385295',
          amount:                            39.99,
          instruction:                       '12',
          reference:                         'XYZ/2013-08-ABO/12345',
          remittance_information:            'Unsere Rechnung vom 10.08.2013',
          structured_remittance_information: structured_remittance_information
        )

        sdd.to_xml(SPS::PAIN_008_001_02_CH_03)
      end

      it 'should include encoding in the xml string' do
        expect(subject).to include('encoding')
        expect(subject).to include('UTF-8')
      end
    end

    context 'with encoding specified' do
      subject do
        sdd = direct_debit

        sdd.add_transaction(
          name:                              'Zahlemann & Söhne GbR',
          iban:                              'CH9804835011062385295',
          amount:                            39.99,
          instruction:                       '12',
          reference:                         'XYZ/2013-08-ABO/12345',
          remittance_information:            'Unsere Rechnung vom 10.08.2013',
          structured_remittance_information: structured_remittance_information
        )

        sdd.to_xml(SPS::PAIN_008_001_02_CH_03, 'ISO-8859-8')
      end

      it 'should include encoding in the xml string' do
        expect(subject).to include('encoding')
        expect(subject).to include('ISO-8859-8')
      end
    end
  end
end
