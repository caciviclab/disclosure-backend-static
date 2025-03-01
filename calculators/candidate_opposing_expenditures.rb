# Calculate independent expenditures opposing a candidate.
class CandidateOpposingExpenditure
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates = candidates
    @candidates_by_election_filer_id =
      candidates.where('"FPPC" IS NOT NULL').group_by { |row| row.election_name }.transform_values do |values|
        values.index_by { |c| c.FPPC.to_s }
      end
  end

  def fetch
    # Get the total expenditures against candidates by committee.
    # The Filer_NamL can be different in different records for the
    # same Filer_ID.
    expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT election_name, "Cand_ID", "Filer_ID", "Filer_NamL", SUM("Amount") as "Total"
      FROM (
        SELECT election_name, "Cand_ID", "Filer_ID", "Filer_NamL", "Amount"
        FROM independent_candidate_expenditures
        WHERE "Sup_Opp_Cd" = 'O'
      UNION ALL
        SELECT "Ballot_Measure_Election" as election_name, "Cand_ID", "Filer_ID", "Filer_NamL", 0 as "Amount"
        FROM committees, candidates
        WHERE "Cand_ID" = "FPPC" AND "Support_Or_Oppose" = 'O'
      ) U
      GROUP BY election_name, "Cand_ID", "Filer_ID", "Filer_NamL"
    SQL

    total = {}
    expenditure_against_candidate = expenditures.each_with_object({}) do |row, hash|
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
        candidate.save_calculation(:total_opposing, election_total.fetch(filer_id, 0).round(2))

        sorted =
          Array(expenditure_against_candidate[election_name][filer_id]).sort_by { |row| [row['Filer_NamL'], row['Exp_Date']] }

        candidate.save_calculation(:opposition_list, sorted)
      end
    end
  end
end
