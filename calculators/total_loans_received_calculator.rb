class TotalLoansReceivedCalculator
  def initialize(candidates: [])
    @candidates_by_filer_id =
      candidates.where('"FPPC" IS NOT NULL').index_by { |c| c.FPPC }
  end

  def fetch
    @results = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT "Filer_ID", "Amount_A" FROM "efile_COAK_2016_Summary"
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "', '"}')
          AND "Form_Type" = 'F460'
          AND "Line_Item" = '2'
    SQL

    @results.each do |row|
      candidate = @candidates_by_filer_id[row['Filer_ID'].to_i]
      candidate.save_calculation(:total_loans_received, row['Amount_A'].to_f)
    end
  end
end
