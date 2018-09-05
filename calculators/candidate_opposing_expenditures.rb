class CandidateOpposingExpenditure
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @committees = committees
    @candidates = candidates
  end

  def fetch
    # Get the total expenditures against candidates by date.
    expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT "Filer_ID", "Filer_NamL", "Exp_Date", SUM("Amount") as "Total"
      FROM combined_independent_expenditures
      WHERE "Sup_Opp_Cd" = 'O'
      GROUP BY "Filer_ID", "Filer_NamL", "Exp_Date";
    SQL

    total = {}
    expenditure_against_committee = expenditures.each_with_object({}) do |row, hash|
      filer_id = row['Filer_ID'].to_s
      total[filer_id] ||= 0
      total[filer_id] += row['Total']

      hash[filer_id] ||= []
      hash[filer_id] << row
    end

    @committees.each do |committee|
      filer_id = committee['Filer_ID'].to_s
      sorted =
        Array(expenditure_against_committee[filer_id]).sort_by { |row| [row['Filer_NamL'], row['Exp_Date']] }

      committee.save_calculation(:opposition_list, sorted)
    end

    @candidates.each do |candidate|
      filer_id = candidate['FPPC'].to_s
      candidate.save_calculation(:total_opposing, total[filer_id])
    end
  end
end
