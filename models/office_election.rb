class OfficeElection < ActiveRecord::Base
  has_many :candidates, ->(o) { where(election_name: o.election_name) },
    class_name: 'Candidate', foreign_key: 'Office', primary_key: 'title'
  belongs_to :election, foreign_key: :election_name, primary_key: :name

  def metadata
    sorted_candidates = candidates.sort_by do |candidate|
      [-1 * (candidate.calculation(:total_contributions) || 0.0), candidate.Candidate]
    end

    {
      'election' => election.metadata_path[1..-1],
      'candidates' => sorted_candidates.map { |c| slugify(c.Candidate) },
      'title' => title,
      'label' => label,
    }.compact
  end

  def data
    {
      id: id,
      contest_type: 'Office',
      title: title,
      label: label,
      candidates: candidates.map(&:as_json),
    }
  end
end
