# encoding: utf-8
require 'spec_helper'

describe SPS::CreditTransfer do
  let(:message_id_regex) { /SPS-KING\/[0-9a-z_]{22}/ }
  let(:credit_transfer) {
    SPS::CreditTransfer.new(
      name: 'Schuldner GmbH',
      bic:  'RAIFCH22',
      iban: 'CH5481230000001998736'
    )
  }

  describe :new do
    it 'should accept missing options' do
      expect {
        SPS::CreditTransfer.new
      }.to_not raise_error
    end
  end

  describe :add_transaction do
    it 'should add valid transactions' do
      3.times do
        credit_transfer.add_transaction(credit_transfer_transaction)
      end

      expect(credit_transfer.transactions.size).to eq(3)
    end

    it 'should fail for invalid transaction' do
      expect {
        credit_transfer.add_transaction name: ''
      }.to raise_error(ArgumentError)
    end
  end

  describe :to_xml do
    context 'for invalid debtor' do
      it 'should fail' do
        expect {
          SPS::CreditTransfer.new.to_xml
        }.to raise_error(SPS::Error)
      end
    end

    context 'setting creditor address with adrline' do
      subject do
        sct = SPS::CreditTransfer.new(
                name: 'Schuldner GmbH',
                iban: 'CH5481230000001998736',
                bic:  'RAIFCH22'
              )

        sca = SPS::CreditorAddress.new(
                country_code:  'CH',
                address_line1: 'Mustergasse 123',
                address_line2: '1234 Musterstadt'
              )

        sct.add_transaction(
          name:                   'Telekomiker AG',
          bic:                    'CRESCHZZ80A',
          iban:                   'CH9300762011623852957',
          currency:               'CHF',
          amount:                 102.50,
          reference:              'XYZ-1234/123',
          remittance_information: 'Rechnung vom 22.08.2013',
          creditor_address:       sca
        )

        sct
      end

      it 'should validate against pain.001.001.03.ch.02' do
        expect(
          subject.to_xml(SPS::PAIN_001_001_03_CH_02)
        ).to validate_against('pain.001.001.03.ch.02.xsd')
      end
    end

    context 'setting creditor address with structured fields' do
      subject do
        sct = SPS::CreditTransfer.new(
                name: 'Schuldner GmbH',
                iban: 'CH5481230000001998736',
                bic:  'RAIFCH22'
              )

        sca = SPS::CreditorAddress.new(
                country_code:    'CH',
                street_name:     'Mustergasse',
                building_number: '123',
                post_code:       '1234',
                town_name:       'Musterstadt'
              )

        sct.add_transaction(
          name:                   'Telekomiker AG',
          bic:                    'CRESCHZZ80A',
          iban:                   'CH9300762011623852957',
          amount:                 102.50,
          reference:              'XYZ-1234/123',
          remittance_information: 'Rechnung vom 22.08.2013',
          creditor_address:       sca
        )

        sct
      end

      it "should validate against pain.001.001.03.ch.02" do
        expect(subject.to_xml(SPS::PAIN_001_001_03_CH_02))
          .to validate_against("pain.001.001.03.ch.02.xsd")
      end
    end

    context 'for valid debtor' do
      context 'with BIC' do
        subject do
          sct = credit_transfer

          sct.add_transaction(
            name:                   'Telekomiker AG',
            bic:                    'CRESCHZZ80A',
            iban:                   'CH9300762011623852957',
            service_level:          'SEPA',
            amount:                 102.50,
            reference:              'XYZ-1234/123',
            remittance_information: 'Rechnung vom 22.08.2013'
          )

          sct
        end

        it 'should validate against pain.001.001.03.ch.02' do
          expect(subject.to_xml('pain.001.001.03.ch.02')).to validate_against('pain.001.001.03.ch.02.xsd')
        end
      end

      context 'without requested_date given' do
        subject do
          sct = credit_transfer

          sct.add_transaction(
            name:                   'Telekomiker AG',
            bic:                    'CRESCHZZ80A',
            iban:                   'CH9300762011623852957',
            amount:                 102.50,
            reference:              'XYZ-1234/123',
            remittance_information: 'Rechnung vom 22.08.2013'
          )

          sct.add_transaction(
            name:                   'Amazonas GmbH',
            bic:                    'RAIFCH22C32',
            iban:                   'CH7081232000001998736',
            amount:                 59.00,
            reference:              'XYZ-5678/456',
            remittance_information: 'Rechnung vom 21.08.2013'
          )

          sct.to_xml
        end

        it 'should create valid XML file' do
          expect(subject).to validate_against('pain.001.001.03.ch.02.xsd')
        end

        it 'should have message_identification' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/GrpHdr/MsgId', message_id_regex)
        end

        it 'should contain <PmtInfId>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/PmtInfId', /#{message_id_regex}\/1/)
        end

        it 'should contain <ReqdExctnDt>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/ReqdExctnDt', Date.new(1999, 1, 1).iso8601)
        end

        it 'should contain <PmtMtd>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/PmtMtd', 'TRF')
        end

        it 'should contain <BtchBookg>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/BtchBookg', 'true')
        end

        it 'should contain <NbOfTxs>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/NbOfTxs', '2')
        end

        it 'should contain <CtrlSum>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/CtrlSum', '161.50')
        end

        it 'should contain <Dbtr>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/Dbtr/Nm', 'Schuldner GmbH')
        end

        it 'should contain <DbtrAcct>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/DbtrAcct/Id/IBAN', 'CH5481230000001998736')
        end

        it 'should contain <DbtrAgt>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/DbtrAgt/FinInstnId/BIC', 'RAIFCH22')
        end

        it 'should contain <EndToEndId>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf[1]/PmtId/EndToEndId', 'XYZ-1234/123')
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf[2]/PmtId/EndToEndId', 'XYZ-5678/456')
        end

        it 'should contain <Amt>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf[1]/Amt/InstdAmt', '102.50')
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf[2]/Amt/InstdAmt', '59.00')
        end

        it 'should contain <CdtrAgt> for every BIC given' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf[1]/CdtrAgt/FinInstnId/BIC', 'CRESCHZZ80A')
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf[2]/CdtrAgt/FinInstnId/BIC', 'RAIFCH22C32')
        end

        it 'should contain <Cdtr>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf[1]/Cdtr/Nm', 'Telekomiker AG')
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf[2]/Cdtr/Nm', 'Amazonas GmbH')
        end

        it 'should contain <CdtrAcct>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf[1]/CdtrAcct/Id/IBAN', 'CH9300762011623852957')
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf[2]/CdtrAcct/Id/IBAN', 'CH7081232000001998736')
        end

        it 'should contain <RmtInf>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf[1]/RmtInf/Ustrd', 'Rechnung vom 22.08.2013')
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf[2]/RmtInf/Ustrd', 'Rechnung vom 21.08.2013')
        end
      end

      context 'with different requested_date given' do
        subject do
          sct = credit_transfer

          sct.add_transaction(credit_transfer_transaction.merge requested_date: Date.today + 1)
          sct.add_transaction(credit_transfer_transaction.merge requested_date: Date.today + 2)
          sct.add_transaction(credit_transfer_transaction.merge requested_date: Date.today + 2)

          sct.to_xml
        end

        it 'should contain two payment_informations with <ReqdExctnDt>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[1]/ReqdExctnDt', (Date.today + 1).iso8601)
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[2]/ReqdExctnDt', (Date.today + 2).iso8601)

          expect(subject).not_to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[3]')
        end

        it 'should contain two payment_informations with different <PmtInfId>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[1]/PmtInfId', /#{message_id_regex}\/1/)
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[2]/PmtInfId', /#{message_id_regex}\/2/)
        end
      end

      context 'with different batch_booking given' do
        subject do
          sct = credit_transfer

          sct.add_transaction(credit_transfer_transaction.merge batch_booking: false)
          sct.add_transaction(credit_transfer_transaction.merge batch_booking: true)
          sct.add_transaction(credit_transfer_transaction.merge batch_booking: true)

          sct.to_xml
        end

        it 'should contain two payment_informations with <BtchBookg>' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[1]/BtchBookg', 'false')
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[2]/BtchBookg', 'true')

          expect(subject).not_to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[3]')
        end
      end

      context 'with transactions containing different group criteria' do
        subject do
          sct = credit_transfer

          sct.add_transaction(credit_transfer_transaction.merge requested_date: Date.today + 1, batch_booking: false, amount: 1)
          sct.add_transaction(credit_transfer_transaction.merge requested_date: Date.today + 1, batch_booking: true,  amount: 2)
          sct.add_transaction(credit_transfer_transaction.merge requested_date: Date.today + 2, batch_booking: false, amount: 4)
          sct.add_transaction(credit_transfer_transaction.merge requested_date: Date.today + 2, batch_booking: true,  amount: 8)
          sct.add_transaction(credit_transfer_transaction.merge requested_date: Date.today + 2, batch_booking: true, category_purpose: 'SALA',  amount: 6)

          sct.to_xml
        end

        it 'should contain multiple payment_informations' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[1]/ReqdExctnDt', (Date.today + 1).iso8601)
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[1]/BtchBookg', 'false')

          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[2]/ReqdExctnDt', (Date.today + 1).iso8601)
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[2]/BtchBookg', 'true')

          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[3]/ReqdExctnDt', (Date.today + 2).iso8601)
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[3]/BtchBookg', 'false')

          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[4]/ReqdExctnDt', (Date.today + 2).iso8601)
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[4]/BtchBookg', 'true')

          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[5]/ReqdExctnDt', (Date.today + 2).iso8601)
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[5]/PmtTpInf/CtgyPurp/Cd', 'SALA')
        end

        it 'should have multiple control sums' do
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[1]/CtrlSum', '1.00')
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[2]/CtrlSum', '2.00')
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[3]/CtrlSum', '4.00')
          expect(subject).to have_xml('//Document/CstmrCdtTrfInitn/PmtInf[4]/CtrlSum', '8.00')
        end
      end

      context 'with instruction given' do
        subject do
          sct = credit_transfer

          sct.add_transaction(
            name:        'Telekomiker AG',
            iban:        'CH5481230000001998736',
            bic:         'RAIFCH22',
            amount:      102.50,
            instruction: '1234/ABC'
          )

          sct.to_xml
        end

        it 'should create valid XML file' do
          expect(subject).to validate_against('pain.001.001.03.ch.02.xsd')
        end

        it 'should contain <InstrId>' do
          expect(subject)
            .to have_xml(
              '//Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf[1]/PmtId/InstrId',
              '1234/ABC'
            )
        end
      end
    end
  end
end
