require 'set'

class TotalContributionsCalculator
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates_by_filer_id =
      candidates.where('"FPPC" IS NOT NULL').index_by { |c| c.FPPC.to_s }
  end

  def fetch
    contributions_by_filer_id = {}

    summary_results = ActiveRecord::Base.connection.execute <<-SQL
      SELECT "Filer_ID", SUM("Amount_A") AS "Amount_A"
      FROM "Summary"
      WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "', '"}')
      AND "Form_Type" = 'F460'
      AND "Line_Item" = '5'
      GROUP BY "Filer_ID"
      ORDER BY "Filer_ID"
    SQL

    summary_results.each do |result|
      filer_id = result['Filer_ID'].to_s
      contributions_by_filer_id[filer_id] ||= 0
      contributions_by_filer_id[filer_id] += result['Amount_A'].to_f
    end

    # NOTE: We remove duplicate transactions on 497 that are also reported on
    # Schedule A during a preprocssing script. (See
    # `./../remove_duplicate_transactionts.sh`)
    late_results = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT "Filer_ID", SUM("Amount") AS "Total"
      FROM "497"
      WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
      AND "Form_Type" = 'F497P1'
      GROUP BY "Filer_ID"
      ORDER BY "Filer_ID"
    SQL

    late_results.index_by { |row| row['Filer_ID'].to_s }.each do |filer_id, result|
      contributions_by_filer_id[filer_id] ||= 0
      contributions_by_filer_id[filer_id] += result['Total'].to_f
    end

    contributions_by_filer_id.each do |filer_id, total_contributions|
      candidate = @candidates_by_filer_id[filer_id]
      candidate.save_calculation(:total_contributions, total_contributions)
    end
  end
end

