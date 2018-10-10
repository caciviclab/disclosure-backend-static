class TotalExpendituresCalculator
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates_by_filer_id =
      candidates.where('"FPPC" IS NOT NULL').index_by { |c| c.FPPC }
  end

  def fetch
    results = ActiveRecord::Base.connection.execute <<-SQL
      SELECT "Filer_ID", SUM("Amount_A") AS "Amount_A"
      FROM "Summary", oakland_candidates
      WHERE "Filer_ID" = "FPPC"::varchar
      AND "Form_Type" = 'F460'
      AND "Line_Item" = '11'
      AND ("Start_Date" IS NULL OR "Rpt_Date" >= "Start_Date")
      AND ("End_Date" IS NULL OR "Rpt_Date" <= "End_Date")
      GROUP BY "Filer_ID"
      ORDER BY "Filer_ID"
    SQL

    late_expenditures = ActiveRecord::Base.connection.execute <<-SQL
      SELECT "Filer_ID", SUM("Amount") AS "Amount_A"
      FROM "497"
      WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "', '"}')
      AND "Form_Type" = 'F497P2'
      GROUP BY "Filer_ID"
      ORDER BY "Filer_ID"
    SQL

    (results.to_a + late_expenditures.to_a).each do |result|
      candidate = @candidates_by_filer_id[result['Filer_ID'].to_i]
      candidate.save_calculation(:total_expenditures, result['Amount_A'])
    end
  end
end

