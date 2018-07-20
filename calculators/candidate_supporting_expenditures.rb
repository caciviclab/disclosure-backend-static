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
      WITH combined_independent_expenditures AS (
        SELECT
          "FPPC" AS "Filer_ID",
          "Exp_Date" as "Expn_Date",
          "Filer_NamL",
          "Amount"
        FROM "496"
        INNER JOIN "oakland_candidates"
          ON LOWER(TRIM(CONCAT("Cand_NamF", ' ', "Cand_NamL"))) = LOWER("oakland_candidates"."Candidate")
        WHERE "496"."Cand_NamL" IS NOT NULL
          AND "496"."Sup_Opp_Cd" = 'S'
          AND "FPPC" IS NOT NULL

        UNION
        SELECT
          "FPPC" as "Filer_ID",
          "Expn_Date",
          "Filer_NamL",
          "Amount"
        FROM "D-Expenditure"
        INNER JOIN "oakland_candidates"
          ON LOWER(TRIM(CONCAT("Cand_NamF", ' ', "Cand_NamL"))) = LOWER("oakland_candidates"."Candidate")
        WHERE "D-Expenditure"."Cand_NamL" IS NOT NULL
          AND "D-Expenditure"."Sup_Opp_Cd" = 'S'
          AND "FPPC" IS NOT NULL
      )
      SELECT
        "Filer_ID",
        SUM("Amount") as total
      FROM combined_independent_expenditures
      GROUP BY "Filer_ID"
    SQL

    total = {}
    # TODO: Key this based off the candidate name rather than the Filer ID, to
    # support IEs for candidates that haven't filed to run yet.
    expenditures.each_with_object({}) do |row, hash|
      filer_id = row['Filer_ID'].to_s
      total[filer_id] ||= 0
      total[filer_id] += row['total']

      hash[filer_id] ||= []
      hash[filer_id] << row
    end

    @candidates.each do |candidate|
      filer_id = candidate['FPPC']
      candidate.save_calculation(:total_supporting_independent, total.fetch(filer_id.to_s, 0).round(2))
    end
  end
end
