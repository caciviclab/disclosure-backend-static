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
      SELECT "Filer_ID", Sum("Amount") as "Total"
      FROM independent_candidate_expenditures
      WHERE "Sup_Opp_Cd" = 'S'
      GROUP BY "Filer_ID";
    SQL

    total = {}
    # TODO: Key this based off the candidate name rather than the Filer ID, to
    # support IEs for candidates that haven't filed to run yet.
    expenditures.each_with_object({}) do |row, hash|
      filer_id = row['Filer_ID'].to_s
      total[filer_id] ||= 0
      total[filer_id] += row['Total']

      hash[filer_id] ||= []
      hash[filer_id] << row
    end

    @candidates.each do |candidate|
      filer_id = candidate['FPPC']
      candidate.save_calculation(:total_supporting_independent, total.fetch(filer_id.to_s, 0).round(2))
    end
  end
end
