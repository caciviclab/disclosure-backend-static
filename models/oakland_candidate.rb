class OaklandCandidate < ActiveRecord::Base
  belongs_to :office_election, foreign_key: 'Office', primary_key: 'name'

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
    }
  end
end
