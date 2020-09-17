# Calculate independent expenditures opposing a candidate.
class CandidateOpposingExpenditure
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates = candidates
  end

  def fetch
    # Get the total expenditures against candidates by committee.
    # The Filer_NamL can be different in different records for the
    # same Filer_ID.
    expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT "Cand_ID", "Filer_ID", "Filer_NamL", SUM("Amount") as "Total"
      FROM independent_candidate_expenditures
      WHERE "Sup_Opp_Cd" = 'O'
      GROUP BY "Cand_ID", "Filer_ID", "Filer_NamL"
    SQL

    total = {}
    expenditure_against_candidate = expenditures.each_with_object({}) do |row, hash|
      filer_id = row['Cand_ID'].to_s
      total[filer_id] ||= 0
      total[filer_id] += row['Total']

      hash[filer_id] ||= []
      hash[filer_id] << row
    end

    @candidates.each do |candidate|
      filer_id = candidate['FPPC'].to_s
      candidate.save_calculation(:total_opposing, total.fetch(filer_id, 0).round(2))

      sorted =
        Array(expenditure_against_candidate[filer_id]).sort_by { |row| [row['Filer_NamL'], row['Exp_Date']] }

      candidate.save_calculation(:opposition_list, sorted)
    end
  end
end
