class ReferendumContributionsByOrigin
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @ballot_measures = ballot_measures
  end

  def fetch
    contributions = ActiveRecord::Base.connection.execute(<<-SQL)
      WITH contributions_by_locale AS (
        SELECT "Filer_ID",
        CASE
          WHEN LOWER("Tran_City") = 'oakland' THEN 'Within Oakland'
          WHEN UPPER("Tran_State") = 'CA' THEN 'Within California'
          ELSE 'Out of State'
        END AS locale,
        SUM("Tran_Amt1") AS total
        FROM combined_contributions
        GROUP BY "Filer_ID", locale
      )
      SELECT
        "Ballot_Measure" AS "Measure_Number",
        "Support_Or_Oppose" AS "Sup_Opp_Cd",
        contributions_by_locale.locale,
        SUM(contributions_by_locale.total) as total
      FROM contributions_by_locale
      INNER JOIN oakland_committees committees
        ON committees."Filer_ID"::varchar = contributions_by_locale."Filer_ID"::varchar
      GROUP BY "Ballot_Measure", "Support_Or_Oppose", contributions_by_locale.locale
      ORDER BY "Ballot_Measure", "Support_Or_Oppose", contributions_by_locale.locale;
    SQL

    support = {}
    oppose = {}

    contributions.each do |row|
      measure = row['Measure_Number']
      if measure.nil?
        puts 'WARN empty measure number: ' + row.inspect
        next
      end
      support[measure] ||= {}
      oppose[measure] ||= {}

      case row['Sup_Opp_Cd']
      when 'S', 'Support'
        support[measure][row['locale']] = row['total']
      when 'O', 'Oppose'
        oppose[measure][row['locale']] = row['total']
      end
      election = @ballot_measures[measure.to_i].election_name
      ContributionsByOrigin[election] ||= {}
      ContributionsByOrigin[election][row['locale']] ||= 0
      ContributionsByOrigin[election][row['locale']] += row['total']
    end

    [
      [support, :supporting_locales, :supporting_total],
      [oppose, :opposing_locales, :opposing_total],
    ].each do |locales, calculation_name, total_name|
      locales.keys.map do |measure|
        total = 0
        ballot_measure = ballot_measure_from_number(measure)
        result = locales[measure].keys.map do |locale|
          amount = locales[measure][locale]
          total += amount
          {
            locale: locale,
            amount: amount,
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
