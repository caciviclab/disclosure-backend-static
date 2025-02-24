# Calculate independent expenditures in support of a candidate.
class CandidateSupportingExpenditure
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates = candidates
  end

  def fetch
    # Get the total expenditures for candidates by committee.
    # The Filer_NamL can be different in different records for the
    # same Filer_ID.
    expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT election_name, "Cand_ID", "Filer_ID", "Filer_NamL", SUM("Amount") as "Total"
      FROM (
        SELECT election_name, "Cand_ID", "Filer_ID", "Filer_NamL", "Amount"
        FROM independent_candidate_expenditures
        WHERE "Sup_Opp_Cd" = 'S'
      UNION ALL
        SELECT "Ballot_Measure_Election" as election_name, "Cand_ID", "Filer_ID", "Filer_NamL", 0 as "Amount"
        FROM committees, candidates
        WHERE "Cand_ID" = "FPPC" AND "Support_Or_Oppose" = 'S'
      ) U
      GROUP BY election_name, "Cand_ID", "Filer_ID", "Filer_NamL"
    SQL

    total = {}
    # TODO: Key this based off the candidate name rather than the Filer ID, to
    # support IEs for candidates that haven't filed to run yet.
   expenditure_for_candidate = expenditures.each_with_object({}) do |row, hash|
      election_name = row['election_name']
      filer_id = row['Cand_ID'].to_s
      total[election_name] ||= {}
      total[election_name][filer_id] ||= 0
      total[election_name][filer_id] += row['Total']

      hash[election_name] ||= {}
      hash[election_name][filer_id] ||= []
      hash[election_name][filer_id] << row
    end

    @candidates.each do |candidate|
      election_name = candidate['election_name']
      filer_id = candidate['FPPC'].to_s
      election_total = total[election_name]
      if !election_total.nil?
        total_supporting_independent = election_total.fetch(filer_id, 0)
        candidate.save_calculation(:total_supporting_independent, total_supporting_independent.round(2))

        sorted =
          Array(expenditure_for_candidate[election_name][filer_id]).sort_by { |row| [row['Filer_NamL'], row['Expn_Date']] }

        candidate.save_calculation(:support_list, sorted)
      end
    end
  end
end
