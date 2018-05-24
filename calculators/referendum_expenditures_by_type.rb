class ReferendumExpendituresByType
  TYPE_DESCRIPTIONS = {
    'IND' => 'Individual',
    'COM' => 'Committee',
    'OTH' => 'Other (includes Businesses)',
    'SLF' => 'Self Funding'
  }

  def initialize(candidates: [], ballot_measures: [], committees: [])
    @ballot_measures = ballot_measures
    @committees_by_filer_id =
      committees.where('"Filer_ID" IS NOT NULL').index_by { |c| c.Filer_ID }
  end

  def fetch
    # Get the total expenditures.  If the contributions are less than this
    # then the remainder will be from this committee.
    expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT "Measure_Number", "Sup_Opp_Cd", sum("Amount") AS total
      FROM "Measure_Expenditures"
      GROUP BY "Measure_Number", "Sup_Opp_Cd"
    SQL

    contributions = ActiveRecord::Base.connection.execute(<<-SQL)
      WITH contributions_by_type AS (
        SELECT "Filer_ID",
        CASE
          WHEN "Entity_Cd" = 'SCC' THEN 'COM'
          ELSE "Entity_Cd"
        END AS type,
        SUM("Tran_Amt1") AS total
        FROM combined_contributions
        GROUP BY "Filer_ID", type
      )
      SELECT
        "Ballot_Measure" AS "Measure_Number",
        "Support_Or_Oppose" AS "Sup_Opp_Cd",
        contributions_by_type.type,
        SUM(contributions_by_type.total) as total
      FROM "oakland_committees" committees, contributions_by_type
      WHERE committees."Filer_ID" = contributions_by_type."Filer_ID"
      GROUP BY "Ballot_Measure", "Support_Or_Oppose", contributions_by_type.type
      ORDER BY "Ballot_Measure", "Support_Or_Oppose", contributions_by_type.type;
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
        support[row['Measure_Number']][TYPE_DESCRIPTIONS[row['type']]] = row['total']
      elsif row['Sup_Opp_Cd'] == 'O'
        oppose[row['Measure_Number']] ||= {}
        oppose[row['Measure_Number']][TYPE_DESCRIPTIONS[row['type']]] = row['total']
      end
    end

    [
      [support_total, support, :supporting_type],
      [oppose_total, oppose, :opposing_type],
    ].each do |expenditures, by_type, calculation_name|
      expenditures.keys.each do |measure|
        ballot_measure = ballot_measure_from_number(measure)

        if ballot_measure.nil?
          puts 'WARN: Could not find ballot measure: ' + measure.inspect
          next
        end
        if by_type[measure].nil?
          puts 'WARN: No data for ' + calculation_name.inspect + ': ' + measure.inspect
          next
        end

        result = by_type[measure].keys.map do |type|
          amount = by_type[measure][type]
          expenditures[measure] -= amount
          {
            type: type,
            amount: amount,
          }
        end
        if expenditures[measure] > 0
          result << {
            type: 'COM',
            amount: expenditures[measure],
          }
        end
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
