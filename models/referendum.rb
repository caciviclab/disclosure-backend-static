class Referendum < ActiveRecord::Base
  include HasCalculations

  belongs_to :election, foreign_key: :election_name, primary_key: :name

  def metadata
    {
      'election' => election.date.to_s,
      'locality' => election.locality,
      'number' => self[:Measure_number] =~ /PENDING/ ? nil : self[:Measure_number],
      'title' => self[:Short_Title],
      'data_warning' => data_warning,
    }
  end

  def data
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

  def supporting_data
    data.merge(
      round_numbers(
        contributions_by_region: calculation(:supporting_locales) || [],
        contributions_by_type: calculation(:supporting_type) || [],
        supporting_organizations: calculation(:supporting_organizations) || [],
        total_contributions: calculation(:supporting_total) || [],
      )
    )
  end

  def opposing_data
    data.merge(
      round_numbers(
        contributions_by_region: calculation(:opposing_locales) || [],
        contributions_by_type: calculation(:opposing_type) || [],
        opposing_organizations: calculation(:opposing_organizations) || [],
        total_contributions: calculation(:opposing_total) || [],
      )
    )
  end
end
