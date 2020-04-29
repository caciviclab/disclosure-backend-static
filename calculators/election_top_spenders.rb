class ElectionTopSpender
  def initialize(candidates: [], ballot_measures: [], committees: []); end

  def fetch
    election_results = ActiveRecord::Base.connection.execute <<~SQL
      SELECT "election_name", "Tran_NamL", "Tran_NamF", Sum("Tran_Amt1") as "Total_Amount"
      FROM "combined_contributions"
      WHERE "election_name" <> ''
      GROUP BY "election_name", "Tran_NamL", "Tran_NamF";
    SQL

    results_by_election = election_results.each_with_object({}) do |result, hash|
      hash[result['election_name']] ||= []
      hash[result['election_name']] << result
    end

    top_spenders_by_election = Hash[results_by_election.map do |election_name, spenders|
      [election_name, spenders.sort_by { |s| s['Total_Amount'] }.reverse.first(3)]
    end]

    Election.find_each do |election|
      top_spenders = top_spenders_by_election[election.name]
      next unless top_spenders

      election.save_calculation(:top_spenders, top_spenders)
    end
  end
end
