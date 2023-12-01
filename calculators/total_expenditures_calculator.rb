class TotalExpendituresCalculator
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates_by_filer_id =
      candidates.where('"FPPC" IS NOT NULL').index_by { |c| c.FPPC }
    @candidates_by_election_filer_id =
      candidates.find_all { |c| c.FPPC.present? }.group_by { |row| row.election_name }.transform_values do |values|
        values.index_by { |c| c.FPPC.to_s }
      end
  end

  def fetch
    results = ActiveRecord::Base.connection.execute <<-SQL
      SELECT election_name, "Filer_ID", SUM("Amount_A") AS "Amount_A"
      FROM "Summary", candidates
      WHERE "Filer_ID" = "FPPC"::varchar
      AND "Form_Type" = 'F460'
      AND "Line_Item" = '11'
      AND ("Start_Date" IS NULL OR "Rpt_Date" >= "Start_Date")
      AND ("End_Date" IS NULL OR "Rpt_Date" <= "End_Date")
      GROUP BY election_name, "Filer_ID"
      ORDER BY election_name, "Filer_ID"
    SQL

    late_expenditures = ActiveRecord::Base.connection.execute <<-SQL
      SELECT election_name, "Filer_ID", SUM("Amount") AS "Amount_A"
      FROM candidate_497
      WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "', '"}')
      AND "Form_Type" = 'F497P2'
      GROUP BY election_name, "Filer_ID"
      ORDER BY election_name, "Filer_ID"
    SQL

    (results.to_a + late_expenditures.to_a).each do |result|
      election_name = result['election_name']
      filer_id = result['Filer_ID'].to_s

      candidate = @candidates_by_election_filer_id[election_name][filer_id]
      candidate.save_calculation(:total_expenditures, result['Amount_A'].round(2))
    end
  end
end
