# Calculate independent expenditures opposing a candidate.
class CandidateOpposingExpenditure
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates = candidates
  end

  def fetch
    # Get the total expenditures against candidates by date.
    expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT candidate_filer_id::varchar, "Filer_ID", "Filer_NamL", SUM("Amount") as "Total"
      FROM independent_candidate_expenditures
      WHERE "Sup_Opp_Cd" = 'O'
      GROUP BY candidate_filer_id, "Filer_ID", "Filer_NamL";
    SQL

    total = {}
    expenditure_against_candidate = expenditures.each_with_object({}) do |row, hash|
      candidate_filer_id = row['candidate_filer_id'].to_s
      total[candidate_filer_id] ||= 0
      total[candidate_filer_id] += row['Total']

      hash[candidate_filer_id] ||= []
      hash[candidate_filer_id] << row
    end

    @candidates.each do |candidate|
      candidate_filer_id = candidate['FPPC'].to_s
      candidate.save_calculation(:total_opposing, total.fetch(candidate_filer_id, 0).round(2))

      sorted =
        Array(expenditure_against_candidate[candidate_filer_id]).sort_by { |row| [row['Filer_NamL'], row['Exp_Date']] }

      candidate.save_calculation(:opposition_list, sorted)
    end
  end
end
