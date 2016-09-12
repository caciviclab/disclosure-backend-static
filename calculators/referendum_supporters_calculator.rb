class ReferendumSupportersCalculator
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @ballot_measures = ballot_measures
  end

  def fetch
    expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT "Filer_ID", "Filer_NamL", "Bal_Name", "Sup_Opp_Cd",
             SUM("Amount") AS "Total_Amount"
        FROM "efile_COAK_2016_E-Expenditure"
       WHERE "Bal_Name" IS NOT NULL
       GROUP BY "Filer_ID", "Filer_NamL", "Bal_Name", "Sup_Opp_Cd";
    SQL

    supporting_by_measure_name = {}
    opposing_by_measure_name = {}

    expenditures.each do |row|
      if row['Sup_Opp_Cd'] == 'S'
        supporting_by_measure_name[row['Bal_Name']] ||= []
        supporting_by_measure_name[row['Bal_Name']] << row
      elsif row['Sup_Opp_Cd'] == 'O'
        opposing_by_measure_name[row['Bal_Name']] ||= []
        opposing_by_measure_name[row['Bal_Name']] << row
      end
    end

    [
      # { bal_name => rows }     , calculation name
      [supporting_by_measure_name, :supporting_organizations],
      [opposing_by_measure_name, :opposing_organizations],
    ].each do |rows_by_bal_name, calculation_name|
      # the processing is the same for both supporting and opposing expenses
      rows_by_bal_name.each do |bal_name, rows|
        ballot_measure = ballot_measure_from_name(bal_name)
        ballot_measure.save_calculation(calculation_name, rows.map do |row|
          # committees in support/opposition:
          {
            id: 'no-id-yet-but-there-will-be-one-here-eventually',
            name: row['Filer_NamL'],
            amount: row['Total_Amount'],
          }
        end)
      end
    end
  end

  private

  def ballot_measure_from_name(bal_name)
    @ballot_measures.detect do |measure|
      measure['Measure_number'] ==
        OaklandReferendum.name_to_measure_number(bal_name)
    end
  end
end
