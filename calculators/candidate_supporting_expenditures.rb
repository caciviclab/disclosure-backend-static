# Calculate independent expenditures in support of a candidate.
class CandidateSupportingExpenditure
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates = candidates
  end

  def fetch
    # Get the total indepedent expenditures for candidates by date.
    expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT candidate_filer_id::varchar, "Filer_ID", "Filer_NamL", SUM("Amount") as "Total"
      FROM independent_candidate_expenditures
      WHERE "Sup_Opp_Cd" = 'S'
      GROUP BY candidate_filer_id, "Filer_ID", "Filer_NamL";
    SQL

    total = {}
    # TODO: Key this based off the candidate name rather than the Filer ID, to
    # support IEs for candidates that haven't filed to run yet.
   expenditure_for_candidate = expenditures.each_with_object({}) do |row, hash|
      candidate_filer_id = row['candidate_filer_id'].to_s
      total[candidate_filer_id] ||= 0
      total[candidate_filer_id] += row['Total']

      hash[candidate_filer_id] ||= []
      hash[candidate_filer_id] << row
    end

    @candidates.each do |candidate|
      candidate_filer_id = candidate['FPPC'].to_s
      candidate.save_calculation(:total_supporting_independent, total.fetch(candidate_filer_id, 0).round(2))

      sorted =
        Array(expenditure_for_candidate[candidate_filer_id]).sort_by { |row| [row['Filer_NamL'], row['Exp_Date']] }

      candidate.save_calculation(:support_list, sorted)
    end
  end
end
