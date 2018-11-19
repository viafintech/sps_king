# encoding: utf-8

def credit_transfer_transaction(attributes={})
  { name:                   'Telekomiker AG',
    bic:                    'RAIFCH22',
    iban:                   'CH5481230000001998736',
    amount:                 102.50,
    reference:              'XYZ-1234/123',
    remittance_information: 'Rechnung vom 22.08.2013'
  }.merge(attributes)
end

def direct_debt_transaction(attributes={})
  {
    name:                      'Müller & Schmidt oHG',
    iban:                      'CH5481230000001998736',
    amount:                    750.00,
    instruction:               '123',
    reference:                 'XYZ/2013-08-ABO/6789',
    remittance_information:    'Vielen Dank für Ihren Einkauf!',
    requested_date:            Date.today + 1,
    structured_remittance_information: structured_remittance_information
  }.merge(attributes)
end

def structured_remittance_information(attributes = {})
  SPS::StructuredRemittanceInformation.new(
    {
      proprietary: 'ESR',
      reference:   '048353234234234353453423423'
    }.merge(attributes)
  )
end
