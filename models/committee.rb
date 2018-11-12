class Committee < ActiveRecord::Base

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
      filer_id: self['Filer_ID'],
      name: self['Filer_NamL'],

      website_url: self['Website'],
      city: self['City'],
      committee_type: self['Committee_Type'],
      description: self['Description'],
      ballot_measure: self['Ballot Measure'],
      facebook: self['Facebook'],
    }
  end
end
