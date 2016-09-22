class ReferendumExpendituresByOrigin
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @ballot_measures = ballot_measures
    @committees_by_filer_id =
      committees.where('"Filer_ID" IS NOT NULL').index_by { |c| c.Filer_ID }
  end

  def fetch
    # Get the total expenditures.  If the contributions are less than this
    # then the remainder will be from "Unknown" locale.
    expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT "Measure_Number", "Sup_Opp_Cd", sum("Amount") AS total
      FROM "efile_COAK_2016_E-Expenditure",
        oakland_name_to_number
      WHERE "Bal_Name" = "Measure_Name"
      GROUP BY "Measure_Number", "Sup_Opp_Cd";
    SQL

    contributions = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT d."Measure_Number", d."Sup_Opp_Cd", A.locale, A.total
      FROM
        (SELECT distinct "Filer_ID", "Measure_Number", "Sup_Opp_Cd"
          FROM "efile_COAK_2016_E-Expenditure",
          oakland_name_to_number
          WHERE "Bal_Name" IS NOT NULL
          AND "Bal_Name" = "Measure_Name") d,
        (SELECT "Filer_ID",
        CASE
          WHEN lower("Tran_City") = 'oakland' THEN 'Within Oakland'
          WHEN upper("Tran_State") = 'CA' THEN 'Within California'
          ELSE 'Out of State'
        END as locale,
        sum("Tran_Amt1") as total
        FROM
          (SELECT "Filer_ID", "Tran_City", "Tran_State", "Tran_Amt1"
          FROM "efile_COAK_2016_A-Contributions"
          UNION
          SELECT CAST("Filer_ID" as VARCHAR(7)),
          "Enty_City" as "Tran_City", "Enty_ST" as "Tran_State",
          "Amount" as "Tran_Amt1"
          FROM "efile_COAK_2016_497") x
        WHERE "Filer_ID" IN (SELECT "Filer_ID"
              FROM "efile_COAK_2016_E-Expenditure"
              WHERE "Bal_Name" IS NOT NULL)
        GROUP BY "Filer_ID", locale) A
      WHERE d."Filer_ID" = A."Filer_ID"
      ORDER BY d."Measure_Number", d."Sup_Opp_Cd";
    SQL

    support_total = {}
    oppose_total = {}

    expenditures.each do |row|
      if row['Sup_Opp_Cd'] == 'S'
        support_total[row['Measure_Number']] = row['total']
      elsif row['Sup_Opp_Cd'] == 'O'
        oppose_total[row['Measure_Number']] = row['total']
      end
    end

    support = {}
    oppose = {}

    contributions.each do |row|
      if row['Sup_Opp_Cd'] == 'S'
        support[row['Measure_Number']] ||= {}
        support[row['Measure_Number']][row['locale']] = row['total']
      elsif row['Sup_Opp_Cd'] == 'O'
        oppose[row['Measure_Number']] ||= {}
        oppose[row['Measure_Number']][row['locale']] = row['total']
      end
    end

    [
      [support_total, support, :supporting_locales, :supporting_total],
      [oppose_total, oppose, :opposing_locales, :opposing_total],
    ].each do |expenditures, locales, calculation_name, total_name|
      totals = {}
      expenditures.keys.each do |measure|
        total = 0
        ballot_measure = ballot_measure_from_number(measure)
        result = locales[measure].keys.map do |locale|
          amount = locales[measure][locale]
          expenditures[measure] -= amount
          total += amount
          {
            locale: locale,
            amount: amount,
          }
        end
        if expenditures[measure] > 0
          total += expenditures[measure]
          result <<
          {
            locale: 'Unknown',
            amount: expenditures[measure],
          }
        end
        ballot_measure.save_calculation(total_name, total)
        ballot_measure.save_calculation(calculation_name, result)
      end
    end
  end
  def ballot_measure_from_number(bal_number)
    @ballot_measures.detect do |measure|
      measure['Measure_number'] == bal_number
    end
  end
end
