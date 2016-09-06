class OaklandReferendum < ActiveRecord::Base

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
