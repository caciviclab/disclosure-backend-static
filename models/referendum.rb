class Referendum < ActiveRecord::Base
  include HasCalculations

  def as_json(options = nil)
    {
      id: id,
      contest_type: 'Referendum',
      name: self['Short_Title'],

      # fields for /referendum/:id
      title: self['Short_Title'],
      summary: self['Summary'],
      number: self['Measure_number'],
      voters_edge_url: self['VotersEdge'],
    }
  end
end
