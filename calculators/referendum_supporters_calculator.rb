class ReferendumSupportersCalculator
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @ballot_measures = ballot_measures
    @committees_by_filer_id =
      committees.where('"Filer_ID" IS NOT NULL').index_by { |c| c.Filer_ID }
  end

  def fetch
    # UNION Schedle E with the 24-Hour IEs from 496.
    expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT "Filer_ID", "Filer_NamL", "Measure_Number", "Bal_Name", "Sup_Opp_Cd",
        SUM("Amount") AS "Total_Amount"
      FROM "Measure_Expenditures"
      GROUP BY "Filer_ID", "Filer_NamL", "Measure_Number", "Bal_Name", "Sup_Opp_Cd"
    SQL

    supporting_by_measure_name = {}
    opposing_by_measure_name = {}

    expenditures.each do |row|
      committee = committee_from_expenditure(row)
      bal_num = row['Measure_Number']

      unless bal_num
        $stderr.puts "COULD NOT FIND BALLOT MEASURE: #{row['Bal_Name'].inspect}"
        $stderr.puts "  Add it to the Oakland Candidates spreadsheet"
        $stderr.puts "  Debug: #{row.inspect}"
        next
      end

      # TODO: track number of skips (#35)
      next if bal_num == 'SKIP'

      if row['Sup_Opp_Cd'] == 'Unknown'
        # TODO: track number of guesses (#35)
        row['Sup_Opp_Cd'] = guess_whether_committee_supports_measure(row['Filer_ID'], row['Bal_Name'])
      end

      if row['Sup_Opp_Cd'] == 'S'
        supporting_by_measure_name[bal_num] ||= {}
        supporting_by_measure_name[bal_num][row['Filer_ID']] ||= {
          id: committee ? committee['Filer_ID'] : nil,
          name: committee ? committee['Filer_NamL'] : row['Filer_NamL'],
          payee: committee ? committee['Filer_NamL'] : row['Filer_NamL'],
          amount: 0,
        }
        supporting_by_measure_name[bal_num][row['Filer_ID']][:amount] += row['Total_Amount']
      elsif row['Sup_Opp_Cd'] == 'O'
        opposing_by_measure_name[bal_num] ||= {}
        opposing_by_measure_name[bal_num][row['Filer_ID']] ||= {
          id: committee ? committee['Filer_ID'] : nil,
          name: committee ? committee['Filer_NamL'] : row['Filer_NamL'],
          payee: committee ? committee['Filer_NamL'] : row['Filer_NamL'],
          amount: 0,
        }
        opposing_by_measure_name[bal_num][row['Filer_ID']][:amount] += row['Total_Amount']
      elsif
        $stderr.puts "unknown support: #{row}"
      end
    end

    [
      # { bal_name => rows }     , calculation name
      [supporting_by_measure_name, :supporting_organizations],
      [opposing_by_measure_name, :opposing_organizations],
    ].each do |rows_by_bal_num, calculation_name|
      # the processing is the same for both supporting and opposing expenses
      rows_by_bal_num.each do |bal_num, rows|
        ballot_measure = ballot_measure_from_num(bal_num)
        ballot_measure.save_calculation(calculation_name, rows.values)
      end
    end
  end

  private

  def ballot_measure_from_num(bal_num)
    @ballot_measures.detect { |measure| measure['Measure_number'] == bal_num }
  end

  def committee_from_expenditure(expenditure)
    committee = @committees_by_filer_id[expenditure['Filer_ID']]

    unless committee
      @committees_by_filer_id.each do |id, cmte|
        if expenditure['Filer_NamL'] =~ /#{Regexp.escape cmte.Filer_NamL}/i
          committee = cmte
          break
        end
      end
    end

    committee
  end

  # Form 497 Page 2 (Late Expenditures) includes the ballot measure name and
  # committee ID, but does not indicate whether that expenditure was in support
  # or opposition of the ballot measure.
  #
  # This is not perfect, but it should get us pretty close.
  def guess_whether_committee_supports_measure(committee_id, bal_name)
    @_guess_cache ||=
      begin
        guesses = ActiveRecord::Base.connection.execute(<<-SQL)
          SELECT "Filer_ID", "Bal_Name", "Sup_Opp_Cd"
          FROM "efile_COAK_2016_E-Expenditure"
          WHERE "Bal_Name" IS NOT NULL
          GROUP BY "Filer_ID", "Bal_Name", "Sup_Opp_Cd"
        SQL

        guesses.index_by do |row|
          row.values_at('Filer_ID', 'Bal_Name').map(&:to_s)
        end
      end

    if row = @_guess_cache[[committee_id.to_s, bal_name]]
      row['Sup_Opp_Cd']
    end
  end
end
