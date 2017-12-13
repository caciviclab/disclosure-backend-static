class CandidateOpposingExpenditure
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @committees = committees
    @candidates = candidates
  end

  def fetch
    # Get the total expenditures against candidates by date.
    expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT "FPPC" AS "Filer_ID", "Filer_NamL", "Exp_Date",
      sum("Amount") AS total
      FROM (
        SELECT "Filer_NamL", "Exp_Date",
          "Cand_NamF", "Cand_NamL", "Amount"
        FROM "496"
        WHERE "Cand_NamL" IS NOT NULL
        AND "Sup_Opp_Cd" = 'O'
        UNION ALL
        SELECT "Filer_NamL", "Expn_Date" as "Exp_Date", "Cand_NamF", "Cand_NamL", "Amount"
        FROM "E-Expenditure"
        WHERE "Cand_NamL" IS NOT NULL
        AND "Sup_Opp_Cd" = 'O'
      ) AS U,
      "oakland_candidates"
      WHERE LOWER(TRIM(CONCAT("Cand_NamF", ' ', "Cand_NamL"))) = LOWER("Candidate")
      GROUP BY "FPPC", "Filer_NamL", "Exp_Date"
    SQL

    total = {}
    expenditure_against_committee = expenditures.each_with_object({}) do |row, hash|
      filer_id = row['Filer_ID'].to_s
      total[filer_id] ||= 0
      total[filer_id] += row['total']

      hash[filer_id] ||= []
      hash[filer_id] << row
    end

    @committees.each do |committee|
      filer_id = committee['Filer_ID'].to_s
      sorted =
        Array(expenditure_against_committee[filer_id]).sort_by { |row| row['Filer_NamL'] }

      committee.save_calculation(:opposition_list, sorted)
    end

    @candidates.each do |candidate|
      filer_id = candidate['FPPC'].to_s
      candidate.save_calculation(:total_opposing, total[filer_id])
    end
  end
end
