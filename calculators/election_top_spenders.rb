class ElectionTopSpender
  def initialize(candidates: [], ballot_measures: [], committees: []); end

  def fetch
    election_results = ActiveRecord::Base.connection.execute <<~SQL
      SELECT "election_name", "Type" as type, trim(concat("Tran_NamF",' ', "Tran_NamL")) as name,  Sum("Tran_Amt1") as "total_spending"
      FROM "combined_contributions"
      WHERE "election_name" <> ''
      GROUP BY "election_name", type, name
    SQL

    results_by_election = election_results.each_with_object({}) do |result, hash|
      hash[result['election_name']] ||= {}
      hash[result['election_name']][result['type']] ||= []
      hash[result['election_name']][result['type']] << result
    end

    top_spenders_by_office = {}
    top_spenders_by_measure = {}
    results_by_election.each do |election_name, type|
      unless type['Office'].nil?
        top_spenders_by_office[election_name]  =
          type['Office'].sort_by { |s| s['total_spending'] }.reverse.first(3)
      end
      unless type['Measure'].nil?
        top_spenders_by_measure[election_name]  =
          type['Measure'].sort_by { |s| s['total_spending'] }.reverse.first(3)
      end
    end

    top_spenders_by_election =
      top_spenders_by_office.merge(top_spenders_by_measure) {
      |key, oldval, newval| (oldval + newval).sort_by { |s| s['total_spending'] }.reverse.      first(3)
    }

    Election.find_each do |election|
      top_spenders = top_spenders_by_election[election.name]
      unless top_spenders.nil?
        election.save_calculation(:top_spenders, top_spenders)
      end

      top_spenders = top_spenders_by_office[election.name]
      unless top_spenders.nil?
        election.save_calculation(:top_spenders_for_offices, top_spenders)
      end
      top_spenders = top_spenders_by_measure[election.name]
      unless top_spenders.nil?
        election.save_calculation(:top_spenders_for_measures, top_spenders)
      end
    end
  end
end
