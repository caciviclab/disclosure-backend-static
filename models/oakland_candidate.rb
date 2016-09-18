class OaklandCandidate < ActiveRecord::Base
  belongs_to :office_election, foreign_key: 'Office', primary_key: 'name'

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
    first_name, last_name = self['Candidate'].split(' ', 2) # Probably wrong!

    {
      id: id,
      name: self['Candidate'],

      # fields for /candidate/:id
      photo_url: self['Photo'],
      website_url: self['Website'],
      twitter_url: self['Twitter'],
      first_name: first_name,
      last_name: last_name,
      ballot_item: office_election.id,
      office_election: office_election.id,

      # contribution data
      supporting_money: {
        contributions_received: calculation(:total_contributions).try(:to_f),
        total_contributions: calculation(:total_contributions).try(:to_f),
        total_expenditures: calculation(:total_expenditures).try(:to_f),
        total_loans_received: calculation(:total_loans_received).try(:to_f),
        contributions_by_type: calculation(:contributions_by_type) || {},
        expenditures_by_type: calculation(:expenditures_by_type) || {},
      },
      opposing_money: {
        contributions_received: 4567,
      },

      # for backwards compatibility, these should also be exposed at the
      # top-level:
      # TODO: remove once the frontend no longer uses this
      contributions_received: calculation(:total_contributions).try(:to_f),
      total_contributions: calculation(:total_contributions).try(:to_f),
      total_expenditures: calculation(:total_expenditures).try(:to_f),
      total_loans_received: calculation(:total_loans_received).try(:to_f),
      contributions_by_type: calculation(:contributions_by_type) || {},
      expenditures_by_type: calculation(:expenditures_by_type) || {},
    }
  end
end
