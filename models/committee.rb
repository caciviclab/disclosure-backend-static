class Committee < ActiveRecord::Base
  include HasCalculations

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
