class OfficeElection < ActiveRecord::Base
  has_many :candidates, class_name: 'Candidate', foreign_key: 'Office', primary_key: 'name'

  def as_json(options = nil)
    {
      id: id,
      contest_type: 'Office',
      title: title,
      label: label,
      candidates: candidates.map(&:as_json),
    }
  end
end
