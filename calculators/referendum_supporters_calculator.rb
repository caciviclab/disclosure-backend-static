class ReferendumSupportersCalculator
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @ballot_measures = ballot_measures
    @committees_by_filer_id =
      committees.find_all { | c| c['Filer_ID'].present? }.index_by { |c| c.Filer_ID }
  end

  def fetch
    # UNION Schedle E with the 24-Hour IEs from 496.
    expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT "Filer_ID", "Filer_NamL", "election_name", "Measure_Number", "Bal_Name", "Sup_Opp_Cd", "Recipient_Or_Description",
        SUM("Amount") AS "Total_Amount"
      FROM "Measure_Expenditures"
      GROUP BY "Filer_ID", "Filer_NamL", "election_name", "Measure_Number", "Bal_Name", "Sup_Opp_Cd", "Recipient_Or_Description"
      ORDER BY "Filer_NamL" ASC
    SQL

    summary_other = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT "Filer_ID", SUM("Amount_A") as "Summary_Other_Expenditures"
      FROM "Summary"
      WHERE "Form_Type" = 'F460'
      AND "Committee_Type" = 'BMC'        -- Ignore recipient committees' summary
                                          --   data since it represents more than
                                          --   just ballot measure expenditures
      AND (
        "Line_Item" = '9'                 -- "Accrued Expenses (Unpaid Bills)"
        OR "Line_Item" = '10'             -- "Non-monetary Adjustment"
      )
      GROUP BY "Filer_ID"
    SQL
    summary_other = summary_other.index_by { |r| r['Filer_ID'] }

    supporting_by_measure_name = {}
    opposing_by_measure_name = {}

    expenditures.each do |row|
      committee = committee_from_expenditure(row)
      election_name = row['election_name']
      bal_num = row['Measure_Number']

      # TODO: track number of skips (#35)
      next if bal_num == 'SKIP'

      unless bal_num
        $stderr.puts "COULD NOT FIND BALLOT MEASURE: #{row['Bal_Name'].inspect}"
        $stderr.puts "  Add it to the 'Referendum Name to Number' sheet"
        $stderr.puts "  Debug: #{row.inspect}"
        next
      end

      if row['Sup_Opp_Cd'] == 'Unknown'
        # TODO: track number of guesses (#35)
        row['Sup_Opp_Cd'] = guess_whether_committee_supports_measure(row['Filer_ID'], row['Bal_Name'])
      end

      if row['Sup_Opp_Cd'] == 'S'
        supporting_by_measure_name[[election_name, bal_num]] ||= {}
        supporting_by_measure_name[[election_name, bal_num]][row['Filer_ID']] ||= {
          id: committee ? committee['Filer_ID'] : nil,
          name: committee ? committee['Filer_NamL'] : row['Filer_NamL'],
          payee: committee ? committee['Filer_NamL'] : row['Filer_NamL'],
          # start with the other items from the summary page (lines 9 + 10)
          amount: summary_other.fetch(row['Filer_ID'], {})['Summary_Other_Expenditures'] || 0,
        }
        supporting_by_measure_name[[election_name, bal_num]][row['Filer_ID']][:amount] += row['Total_Amount']
      elsif row['Sup_Opp_Cd'] == 'O'
        opposing_by_measure_name[[election_name, bal_num]] ||= {}
        opposing_by_measure_name[[election_name, bal_num]][row['Filer_ID']] ||= {
          id: committee ? committee['Filer_ID'] : nil,
          name: committee ? committee['Filer_NamL'] : row['Filer_NamL'],
          payee: committee ? committee['Filer_NamL'] : row['Filer_NamL'],
          # start with the other items from the summary page (lines 9 + 10)
          amount: summary_other.fetch(row['Filer_ID'], {})['Summary_Other_Expenditures'] || 0,
        }
        opposing_by_measure_name[[election_name, bal_num]][row['Filer_ID']][:amount] += row['Total_Amount']
      else
        $stderr.puts
        $stderr.puts "UNKNOWN SUPPORT ($#{row['Total_Amount']}) -- Add to 'Committees' tab:"
        if row['Recipient_Or_Description']
          $stderr.puts "  Recipient or Description: #{row['Recipient_Or_Description']}"
        else
          $stderr.puts '  No recipient information. Contributor information:'
          $stderr.puts "  #{row['Filer_ID']} / #{row['Filer_NamL']} / #{bal_num}"
        end
      end
    end

    # Augment the list of committees that have spent money with the list of
    # committees that have raised money, in case there are some committees that
    # have raised money but not spent it yet.
    augment_lists_with_committees_that_raised_money(supporting_by_measure_name, opposing_by_measure_name)

    [
      # { bal_name => rows }     , calculation name
      [supporting_by_measure_name, :supporting_organizations],
      [opposing_by_measure_name, :opposing_organizations],
    ].each do |rows_by_bal_num, calculation_name|
      # the processing is the same for both supporting and opposing expenses
      rows_by_bal_num.each do |(election_name, bal_num), rows|
        ballot_measure = ballot_measure_from_num(election_name, bal_num)

        if ballot_measure.nil?
          $stderr.puts 'WARN: Could not find ballot measure: ' + bal_num.inspect
          next
        end

        rows.values.map do |supporter_row|
          supporter_row[:amount] = supporter_row[:amount].round(2)
        end

        ballot_measure.save_calculation(calculation_name, rows.values)
      end
    end
  end

  private

  def augment_lists_with_committees_that_raised_money(supporting_by_measure_name, opposing_by_measure_name)
    committees_with_contributions = ActiveRecord::Base.connection.execute(<<-SQL)
    SELECT
      oakland_committees."Filer_ID",
      oakland_committees."Filer_NamL",
      oakland_committees."Ballot_Measure",
      oakland_committees."Ballot_Measure_Election",
      oakland_committees."Support_Or_Oppose"
    FROM combined_contributions
    INNER JOIN oakland_committees
      ON oakland_committees."Filer_ID" = combined_contributions."Filer_ID"
    WHERE "Ballot_Measure" IS NOT NULL
    GROUP BY
      oakland_committees."Filer_ID",
      oakland_committees."Filer_NamL",
      oakland_committees."Ballot_Measure",
      oakland_committees."Ballot_Measure_Election",
      oakland_committees."Support_Or_Oppose";
    SQL
    committees_with_contributions.each do |row|
      election_name = row['Ballot_Measure_Election']
      bal_num = row['Ballot_Measure']
      committee = committee_from_expenditure(row)

      case row['Support_Or_Oppose']
      when 'S'
        supporting_by_measure_name[[election_name, bal_num]] ||= {}
        supporting_by_measure_name[[election_name, bal_num]][row['Filer_ID']] ||= {
          id: committee ? committee['Filer_ID'] : nil,
          name: committee ? committee['Filer_NamL'] : row['Filer_NamL'],
          payee: committee ? committee['Filer_NamL'] : row['Filer_NamL'],
          # start with the other items from the summary page (lines 9 + 10)
          amount: 0,
        }
      when 'O'
        opposing_by_measure_name[[election_name, bal_num]] ||= {}
        opposing_by_measure_name[[election_name, bal_num]][row['Filer_ID']] ||= {
          id: committee ? committee['Filer_ID'] : nil,
          name: committee ? committee['Filer_NamL'] : row['Filer_NamL'],
          payee: committee ? committee['Filer_NamL'] : row['Filer_NamL'],
          # start with the other items from the summary page (lines 9 + 10)
          amount: 0,
        }
      end
    end
  end

  def ballot_measure_from_num(election_name, bal_num)
    @ballot_measures.detect do |measure|
      measure['election_name'] == election_name &&
                measure['Measure_number'] == bal_num 
    end
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
          FROM "E-Expenditure"
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
