# Ruby gem for creating SPS XML files

[![Code Climate](https://codeclimate.com/github/Barzahlen/sps_king/badges/gpa.svg)](https://codeclimate.com/github/Barzahlen/sps_king)
[![Coverage Status](https://coveralls.io/repos/Barzahlen/sps_king/badge.svg?branch=master)](https://coveralls.io/r/Barzahlen/sps_king?branch=master)
[![Gem Version](https://badge.fury.io/rb/sps_king.svg)](http://badge.fury.io/rb/sps_king)

sps_king is a Ruby gem which implements **pain** (**Pa**yment **In**itiation) file building for the Swiss Payment Standard, which is a subset of the ISO 20022 standard.
This is currently implemented in v1.8 for Swiss Credit Transfers (`pain.001.001.03.ch.02`) and v1.2 for Swiss Direct Debits (`pain.008.001.02.ch.03`).

It is a forked of [sepa_king](https://github.com/salesking/sepa_king) and therefore heavily inspired by the structure and the API.


## Requirements

* Ruby 2.1 or newer
* ActiveModel 3.1 or newer


## Installation

    gem install sps_king


## Usage

How to create the XML for **Direct Debit Initiation** (in German: "Lastschriften")

```ruby
# First: Create the main object
sdd = SPS::DirectDebit.new(
  # Name of the initiating party and creditor, in German: "Auftraggeber"
  # String, max. 70 char
  name:       'Gläubiger GmbH',

  # Optional: ISR Participant Number for the swiss ISR debit system. Only for Swiss Direct Debits with ISR references
  # Numeric, 9 digits, last digit is checkdigit recursive with modulo 10
  isr_participant_number: '010001456',

  # International Bank Account Number of the creditor
  # String, max. 34 chars
  iban:       'CH7081232000001998736',

  # Creditor Identifier, in German: Gläubiger-Identifikationsnummer
  # String, max. 35 chars
  creditor_identifier: 'ABC1W'
)

# Second: Add transactions
sdd.add_transaction(
  # Name of the debtor, in German: "Zahlungspflichtiger"
  # String, max. 70 char
  name:                      'Zahlemann & Söhne GbR',

  # International Bank Account Number of the debtor's account
  # String, max. 34 chars
  iban:                      'CH9804835011062385295',

  # Amount
  # Number with two decimal digit
  amount:                    39.99,

  # OPTIONAL: Currency, CHF by default (ISO 4217 standard)
  # String, 3 char
  currency:                  'CHF',

  # Instruction Identification, will not be submitted to the debtor
  # String, max. 35 char
  instruction:               '12345',

  # OPTIONAL: End-To-End-Identification, will be submitted to the debtor
  # String, max. 35 char
  reference:                 'XYZ/2013-08-ABO/6789',

  # OPTIONAL: Unstructured remittance information, in German "Verwendungszweck"
  # String, max. 140 char
  remittance_information:    'Vielen Dank für Ihren Einkauf!',

  # OPTIONAL: Structured remittance information, in German "Strukturierter Verwendungszweck". Required for e.g. Swiss Direct Debits
  # StructuredRemittanceInformation
  structured_remittance_information: SPS::StructuredRemittanceInformation.new(
    # Defines how the reference field should be interpreted for Swiss Direct Debits
    # One of these strings:
    #   'ESR' ("ESR-Referenznummer")
    #   'IPI' ("IPI-Verwendungszweck")
    proprietary: 'ESR',
    # if proprietary is 'ESR': 27 character ISR reference number
    # if proprietary is 'IPI': 20 character IPI remittance
    reference:   '609323234234234353453423423'
  ),

  # Service Level
  # One of these strings:
  #   'CHTA' ("Banklastschrift") - Only for Swiss Direct Debits
  #   'CHDD' ("PostFinance-Lastschrift") - Only for Swiss Direct Debits
  service_level: 'CHTA'

  # Local instrument, in German "Lastschriftart"
  # One of these strings:
  #   'DDCOR1' ("Basis-Lastschrift")  - only for service_level 'CHDD'
  #   'DDB2B'  ("Firmen-Lastschrift") - only for service_level 'CHDD'
  #   'LSV+'   ("Basis-Lastschrift")  - only for service_level 'CHTA'
  #   'BDD'    ("Firmen-Lastschrift") - only for service_level 'CHTA'
  local_instrument: 'LSV+',

  # OPTIONAL: Requested collection date, in German "Fälligkeitsdatum der Lastschrift"
  # Date
  requested_date: Date.new(2013,9,5),

  # OPTIONAL: Use a different creditor account
  # CreditorAccount
  creditor_account: SPS::CreditorAccount.new(
    name:                'Creditor Inc.',
    iban:                'CH7081232000001998736',
    creditor_identifier: '12312'
  )

  # Specify the country & address of the debtor (The individually required fields depend on the local legal requirements)
  debtor_address: SPS::DebtorAddress.new(
    country_code:        'CH',
    # Not required if individual fields are used
    address_line1:       'Mustergasse 123a',
    address_line2:       '1234 Musterstadt'
    # Not required if address_line1 and address_line2 are used
    street_name:         'Mustergasse',
    post_code:           '1234',
    town_name:           'Musterstadt'
  )
)
sdd.add_transaction ...

# Last: create XML string
xml_string = sdd.to_xml # Use latest schema pain.008.001.02.ch.03
```


How to create the XML for **Credit Transfer Initiation** (in German: "Überweisungen")

```ruby
# First: Create the main object
sct = SPS::CreditTransfer.new(
  # Name of the initiating party and debtor, in German: "Auftraggeber"
  # String, max. 70 char
  name: 'Schuldner GmbH',

  # Business Identifier Code (SWIFT-Code) of the debtor
  # String, 8 or 11 char
  bic:  'RAIFCH22',

  # International Bank Account Number of the debtor
  # String, max. 34 chars
  iban: 'CH5481230000001998736'
)

# Second: Add transactions
sct.add_transaction(
  # Name of the creditor, in German: "Zahlungsempfänger"
  # String, max. 70 char
  name:                   'Telekomiker AG',

  # Business Identifier Code (SWIFT-Code) of the creditor's account
  # String, 8 or 11 char
  bic:                    'CRESCHZZ80A',

  # International Bank Account Number of the creditor's account
  # String, max. 34 chars
  iban:                   'CH9300762011623852957',

  # Amount
  # Number with two decimal digit
  amount:                 102.50,

  # OPTIONAL: Currency, CHF by default (ISO 4217 standard)
  # String, 3 char
  currency:               'CHF',

  # OPTIONAL: Instruction Identification, will not be submitted to the creditor
  # String, max. 35 char
  instruction:               '12345',

  # OPTIONAL: End-To-End-Identification, will be submitted to the creditor
  # String, max. 35 char
  reference:              'XYZ-1234/123',

  # OPTIONAL: Unstructured remittance information, in German "Verwendungszweck"
  # String, max. 140 char
  remittance_information: 'Rechnung vom 22.08.2013',

  # OPTIONAL: Requested execution date, in German "Ausführungstermin"
  # Date
  requested_date: Date.new(2013,9,5),

  # OPTIONAL: Enables or disables batch booking, in German "Sammelbuchung / Einzelbuchung"
  # True or False
  batch_booking: true,

  # OPTIONAL: Urgent Payment
  # One of these strings:
  #   'SEPA' ("SEPA-Zahlung")
  #   'URGP' ("Taggleiche Eilüberweisung")
  service_level: 'URGP'

  # OPTIONAL: Unstructured information to indicate the purpose of the payment
  # String, max. 4 char
  category_purpose:         'SALA',

  # Specify the country & address of the creditor. The required fields may vary depending on the legal requirements.
  creditor_address: SPS::CreditorAddress.new(
    country_code:        'CH',
    # Not required if individual fields are used
    address_line1:       'Mustergasse 123a',
    address_line2:       '1234 Musterstadt'
    # Not required if address_line1 and address_line2 are used
    street_name:         'Mustergasse',
    building_number:     '123a',
    post_code:           '1234',
    town_name:           'Musterstadt'
  )
)
sct.add_transaction ...

# Last: create XML string
xml_string = sct.to_xml # Use latest schema pain.001.001.03.ch.02
```

## Changelog

https://github.com/Barzahlen/sps_king/releases


## Contributors

https://github.com/Barzahlen/sps_king/graphs/contributors


## Resources

* https://www.six-group.com/interbank-clearing/de/home/standardization/iso-payments/customer-bank/implementation-guidelines.html
* https://www.lsv.ch/en/home/financial-institutions/direct-debit-procedures/support.html
* https://www.six-group.com/interbank-clearing/de/home/bank-master-data/inquiry-bc-number.html

## License

Released under the MIT license

Copyright (c) 2018 Tobias Schoknecht
Copyright (c) 2013-2017 Georg Leciejewski (Sales King GmbH) & Georg Ledermann for portions of this project copied from sepa_king
