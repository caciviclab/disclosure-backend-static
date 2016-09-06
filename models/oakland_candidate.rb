class OaklandCandidate < ActiveRecord::Base
  belongs_to :office_election, foreign_key: 'Office', primary_key: 'name'
end
