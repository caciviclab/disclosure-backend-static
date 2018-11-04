class TotalLoansReceivedCalculator
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates_by_filer_id =
      candidates.where('"FPPC" IS NOT NULL').index_by { |c| c.FPPC }
  end

  def fetch
    @results = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT "Filer_ID", SUM("Amount_A") AS "Amount_A"
      FROM "Summary"
      WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "', '"}')
      AND "Form_Type" = 'F460'
      AND "Line_Item" = '2'
      GROUP BY "Filer_ID"
      ORDER BY "Filer_ID"
    SQL

    @results.each do |row|
      filer_id = row['Filer_ID'].to_i
      candidate = @candidates_by_filer_id[filer_id]
      unless candidate
        puts "ERROR unknown candidate filer_id=#{filer_id}"
        return
      end
      candidate.save_calculation(:total_loans_received, row['Amount_A'].to_f)
    end
  end
end
