class OaklandReferendum < ActiveRecord::Base
  NETFILE_NAMES_TO_MEASURE_NUMBER = {
    'City of Oakland Soda Tax' => 'HH',
    'CITY OF OAKLAND SODA TAX' => 'HH',
    'MEASURE HH' => 'HH',
    'SUGAR-SWEETENED DRINKS DISTRIBUTOR TAX' => 'HH',

    'Proposed amendments to residental rent adjustments and evictions ordinance' => 'JJ',
    'City of Oakland Renters Upgrade Act' => 'JJ',

    'MEASURE G1' => 'G1',
    "Oakland Infrastructure and Housing Bond Measure" => 'KK',
    'Investing in Oakland?s Infrastructure and Affordable Housing' => 'KK',
    'Oversight of Police Department' => 'LL',

    # Non-Oakland measures: (Skip these because we don't want them to collide.)
    # TODO: scope these ballot measures by jurisdiction
    "Renewal of the Utility User's Tax, Measure D" => 'SKIP',
    "Alameda County Affordable Housing Bond" => 'SKIP',
    "BART Safety, Reliability and Traffic Relief" => 'SKIP',
  }

  def self.name_to_measure_number(name)
    NETFILE_NAMES_TO_MEASURE_NUMBER[name]
  end

  has_many :calculations, as: :subject

  def calculation(name)
    @_calculations_cache ||= calculations.index_by(&:name)
    @_calculations_cache[name.to_s].try(:value)
  end

  def save_calculation(name, value)
    calculations
      .where(name: name)
      .first_or_create
      .update_attributes(value: value)
  end

  def as_json(options = nil)
    {
      id: id,
      contest_type: 'Referendum',
      name: self['Short_Title'],

      # fields for /referendum/:id
      title: self['Short_Title'],
      summary: self['Summary'],
      number: self['Measure_number'],
    }
  end
end
