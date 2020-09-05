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
      SELECT "Cand_ID", i."Filer_ID", c."Filer_NamL", "Total"
      FROM
      (
        SELECT "Cand_ID", "Filer_ID", SUM("Amount") as "Total"
        FROM independent_candidate_expenditures
        WHERE "Sup_Opp_Cd" = 'S'
        GROUP BY "Cand_ID", "Filer_ID"
      ) i
      JOIN
      (
        SELECT DISTINCT ON ("Filer_ID") "Filer_ID", "Filer_NamL"
        FROM committees
      ) c
      ON c."Filer_ID" = i."Filer_ID";
    SQL

    total = {}
    # TODO: Key this based off the candidate name rather than the Filer ID, to
    # support IEs for candidates that haven't filed to run yet.
   expenditure_for_candidate = expenditures.each_with_object({}) do |row, hash|
      filer_id = row['Cand_ID'].to_s
      total[filer_id] ||= 0
      total[filer_id] += row['Total']

      hash[filer_id] ||= []
      hash[filer_id] << row
    end

    @candidates.each do |candidate|
      filer_id = candidate['FPPC'].to_s
      candidate.save_calculation(:total_supporting_independent, total.fetch(filer_id, 0).round(2))

      sorted =
        Array(expenditure_for_candidate[filer_id]).sort_by { |row| [row['Filer_NamL'], row['Exp_Date']] }

      candidate.save_calculation(:support_list, sorted)
    end
  end
end
