class Candidate < ActiveRecord::Base
  include HasCalculations

  has_one :committee, foreign_key: 'Filer_ID', primary_key: 'FPPC'
  belongs_to :office_election, foreign_key: 'Office', primary_key: 'title'
  belongs_to :election, foreign_key: 'election_name', primary_key: 'name'

  def metadata
    {
      'election' => "_elections/#{election.locality}/#{election.date}.md",
      'committee_name' => self[:Committee_Name],
      'data_warning' => self[:data_warning],
      'filer_id' => self[:FPPC].to_s,
      'is_accepted_expenditure_ceiling' => self[:Accepted_expenditure_ceiling],
      'is_incumbent' => self[:Incumbent],
      'name' => self[:Candidate],
      'occupation' => self[:Occupation],
      'party_affiliation' => self[:Party_Affiliation],
      'photo_url' => self[:Photo],
      'public_funding_received' => self[:Public_Funding_Received],
      'twitter_url' => self[:Twitter],
      'votersedge_url' => self[:VotersEdge],
      'website_url' => self[:Website],
    }.compact
  end

  def data
    first_name, last_name = self['Candidate'].split(' ', 2) # Probably wrong!

    round_numbers(
      id: id,
      name: self['Candidate'],

      # fields for /candidate/:id
      photo_url: self['Photo'],
      website_url: self['Website'],
      twitter_url: self['Twitter'],
      votersedge_url: self['VotersEdge'],
      first_name: first_name,
      last_name: last_name,
      ballot_item: office_election.id,
      office_election: office_election.id,
      bio: self['Bio'],
      committee_name: self['Committee_Name'],
      is_accepted_expenditure_ceiling: self['Accepted_expenditure_ceiling'],
      is_incumbent: self['Incumbent'],
      occupation: self['Occupation'],
      party_affiliation: self['Party_Affiliation'],
      is_winner: self['is_winner'],

      # contribution data
      filer_id: self['FPPC'],
      supporting_money: {
        contributions_received: calculation(:total_contributions).try(:to_f) ||
          calculation(:contribution_list_total).try(:to_f),
        total_contributions: calculation(:total_contributions).try(:to_f) ||
          calculation(:contribution_list_total).try(:to_f),
        total_expenditures: calculation(:total_expenditures).try(:to_f),
        total_loans_received: calculation(:total_loans_received).try(:to_f),
        total_supporting_independent: calculation(:total_supporting_independent).try(:to_f),
        support_list: round_numbers(calculation(:support_list) || []),
        contributions_by_type: calculation(:contributions_by_type) || {},
        contributions_by_origin: calculation(:contributions_by_origin) || {},
        total_small_contributions: calculation(:total_small_contributions).try(:to_f),
        expenditures_by_type: calculation(:expenditures_by_type) || {},
        supporting_by_type: calculation(:supporting_by_type) || {},
      },
      opposing_money: {
        opposing_expenditures: calculation(:total_opposing).try(:to_f),
        opposing_by_type: calculation(:opposing_by_type) || {},
        opposition_list: round_numbers(calculation(:opposition_list) || []),
      },

      # for backwards compatibility, these should also be exposed at the
      # top-level:
      # TODO: remove once the frontend no longer uses this
      total_contributions: calculation(:total_contributions).try(:to_f) ||
        calculation(:contribution_list_total).try(:to_f),
      total_expenditures: calculation(:total_expenditures).try(:to_f),
      total_loans_received: calculation(:total_loans_received).try(:to_f),
    )
  end

  # Keep this method in-sync with the `data` method in Committee model.
  def committee_data
    {
      total_contributions: calculation(:contribution_list_total),
      contributions: calculation(:contribution_list) || [],
    }
  end

  private

  def round_numbers(obj)
    case obj
    when Hash
      obj.transform_values { |v| round_numbers(v) }
    when Array
      obj.map { |v| round_numbers(v) }
    when Float
      obj.round(2)
    else
      obj
    end
  end
end
