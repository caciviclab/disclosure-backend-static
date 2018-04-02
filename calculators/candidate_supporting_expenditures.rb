# frozen_string_literal: true

# Calculate independent expenditures in support of a candidate.
class CandidateSupportingExpenditure
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @committees = committees
    @candidates = candidates
  end

  def fetch
    # Get the total indepedent expenditures for candidates by date.
    expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT
        "FPPC" AS "Filer_ID",
        "Filer_NamL",
        SUM("Amount") AS total
      FROM "496"
      INNER JOIN "oakland_candidates"
        ON LOWER(TRIM(CONCAT("Cand_NamF", ' ', "Cand_NamL"))) = LOWER("oakland_candidates"."Candidate")
      WHERE "496"."Cand_NamL" IS NOT NULL
        AND "496"."Sup_Opp_Cd" = 'S'
      GROUP BY "FPPC", "Filer_NamL"
    SQL

    total = {}
    expenditures.each_with_object({}) do |row, hash|
      filer_id = row['Filer_ID'].to_s
      total[filer_id] ||= 0
      total[filer_id] += row['total']

      hash[filer_id] ||= []
      hash[filer_id] << row
    end

    @candidates.each do |candidate|
      filer_id = candidate['FPPC'].to_s
      candidate.save_calculation(:total_supporting_independent, total.fetch(filer_id, 0).round(2))
    end
  end
end
