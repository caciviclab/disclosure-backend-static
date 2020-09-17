class ElectionLargestIndependentExpenditure
  def initialize(candidates: [], ballot_measures: [], committees: []); end

  def fetch
    # An IE may make an expenditure that supports/opposes more than one candidate
    # We use DISTINCT to get rid of these duplicates and add the Date to make
    # surethe are duplicate and not just two of the same on different dates.
    election_results = ActiveRecord::Base.connection.execute <<~SQL
      SELECT election_name, name, Sum("Amount") as total_spending
      FROM
      (
        SELECT "election_name", "Filer_NamL" as name, "Amount", "Exp_Date"
        FROM "Measure_Expenditures"
        WHERE "election_name" <> ''
          AND "Expn_Code" = 'IND'
        UNION ALL
        SELECT DISTINCT "election_name", "Filer_NamL" as name, "Amount", "Exp_Date"
        FROM "independent_candidate_expenditures"
        WHERE "election_name" <> ''
      ) as u
      GROUP BY name, "election_name";
    SQL

    results_by_election = election_results.each_with_object({}) do |result, hash|
      hash[result['election_name']] ||= []
      hash[result['election_name']] << result
    end

    top_spenders_by_election = Hash[results_by_election.map do |election_name, spenders|
      [election_name, spenders.sort_by { |s| s['total_spending'] }.reverse.first(3)]
    end]

    Election.find_each do |election|
      top_spenders = top_spenders_by_election[election.name]
      next unless top_spenders

      election.save_calculation(:largest_independent_expenditures, top_spenders)
    end
  end
end
