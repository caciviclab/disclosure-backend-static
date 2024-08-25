class ElectionTopContributor
  def initialize(candidates: [], ballot_measures: [], committees: []); end

  def fetch
    election_results = ActiveRecord::Base.connection.execute <<~SQL
      SELECT "election_name", "Type" as type,
        trim(concat("Tran_NamF", ' ',"Tran_NamL")) as name,
        Sum("Tran_Amt1") as total_contributions
      FROM "combined_contributions"
      WHERE "election_name" <> ''
      AND "Committee_Type" IN ('CAO', 'CTL', 'BMC', 'SMO')
      GROUP BY "election_name", type, name
      ORDER BY "election_name", type, name;
    SQL

    results_by_election = election_results.each_with_object({}) do |result, hash|
      hash[result['election_name']] ||= {}
      hash[result['election_name']][result['type']] ||= []
      hash[result['election_name']][result['type']] << result
    end

    top_contributors_by_office = {}
    top_contributors_by_measure = {}
    results_by_election.each do |election_name, type|
      unless type['Office'].nil?
        top_contributors_by_office[election_name]  =
          type['Office'].sort_by { |s| s['total_contributions'] }.reverse.first(3)
      end
      unless type['Measure'].nil?
        top_contributors_by_measure[election_name]  =
          type['Measure'].sort_by { |s| s['total_contributions'] }.reverse.first(3)
      end
    end

    election_results = ActiveRecord::Base.connection.execute <<~SQL
      SELECT "election_name", trim(concat("Tran_NamF", ' ',"Tran_NamL")) as name,
        Sum("Tran_Amt1") as total_contributions
      FROM "combined_contributions"
      WHERE "election_name" <> ''
      GROUP BY "election_name", name
      ORDER BY "election_name", name;
    SQL

    results_by_election = election_results.each_with_object({}) do |result, hash|
      hash[result['election_name']] ||= []
      hash[result['election_name']]<< result
    end

    top_contributors_by_election = {}
    results_by_election.each do |election_name, result|
      top_contributors_by_election[election_name] = result.sort_by { |s| s['total_contributions'] }.reverse.first(3)
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
