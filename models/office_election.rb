class OfficeElection < ActiveRecord::Base
  has_many :candidates, class_name: 'OaklandCandidate', foreign_key: 'Office', primary_key: 'name'
end
