class ElectionTopContributor
  def initialize(candidates: [], ballot_measures: [], committees: []); end

  def fetch
    election_results = ActiveRecord::Base.connection.execute <<~SQL
      SELECT "election_name", "Type", "Tran_NamL", "Tran_NamF", Sum("Tran_Amt1") as "Total_Amount"
      FROM "combined_contributions"
      WHERE "election_name" <> ''
      GROUP BY "election_name", "Type", "Tran_NamL", "Tran_NamF";
    SQL

    results_by_election = election_results.each_with_object({}) do |result, hash|
      hash[result['election_name']] ||= {}
      hash[result['election_name']][result['Type']] ||= []
      hash[result['election_name']][result['Type']] << result
    end

    top_contributors_by_office = {}
    top_contributors_by_measure = {}
    results_by_election.each do |election_name, type|
      unless type['Office'].nil?
        top_contributors_by_office[election_name]  =
          type['Office'].sort_by { |s| s['Total_Amount'] }.reverse.first(3)
      end
      unless type['Measure'].nil?
        top_contributors_by_measure[election_name]  =
          type['Measure'].sort_by { |s| s['Total_Amount'] }.reverse.first(3)
      end
    end

    election_results = ActiveRecord::Base.connection.execute <<~SQL
      SELECT "election_name", "Tran_NamL", "Tran_NamF", Sum("Tran_Amt1") as "Total_Amount"
      FROM "combined_contributions"
      WHERE "election_name" <> ''
      GROUP BY "election_name", "Tran_NamL", "Tran_NamF";
    SQL

    results_by_election = election_results.each_with_object({}) do |result, hash|
      hash[result['election_name']] ||= []
      hash[result['election_name']]<< result
    end

    top_contributors_by_election = {}
    results_by_election.each do |election_name, result|
      top_contributors_by_election[election_name] = result.sort_by { |s| s['Total_Amount'] }.reverse.first(3)
    end

    Election.find_each do |election|
      top_contributors = top_contributors_by_election[election.name]
      unless top_contributors.nil?
        election.save_calculation(:top_contributors, top_contributors)
      end

      top_contributors = top_contributors_by_office[election.name]
      unless top_contributors.nil?
        election.save_calculation(:top_contributors_for_offices, top_contributors)
      end
      top_contributors = top_contributors_by_measure[election.name]
      unless top_contributors.nil?
        election.save_calculation(:top_contributors_for_measures, top_contributors)
      end
    end
  end
end
