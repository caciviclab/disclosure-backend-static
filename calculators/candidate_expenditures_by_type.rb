class CandidateExpendituresByType
  TYPE_DESCRIPTIONS = {
    'CMP' => 'Campaign Paraphernalia/Misc.',
    'CNS' => 'Campaign Consultants',
    'CTB' => 'Contribution',
    'CVC' => 'Civic Donations',
    'FIL' => 'Candidate Filing/Ballot Fees',
    'FND' => 'Fundraising Events',
    'IND' => 'Independent Expenditure Supporting/Opposing Others',
    'LEG' => 'Legal Defense',
    'LIT' => 'Campaign Literature and Mailings',
    'MBR' => 'Member Communications',
    'MTG' => 'Meetings and Appearances',
    'OFC' => 'Office Expenses',
    'PET' => 'Petition Circulating',
    'PHO' => 'Phone Banks',
    'POL' => 'Polling and Survey Research',
    'POS' => 'Postage, Delivery and Messenger Services',
    'PRO' => 'Professional Services (Legal, Accounting)',
    'PRT' => 'Print Ads',
    'RAD' => 'Radio Airtime and Production Costs',
    'RFD' => 'Returned Contributions',
    'SAL' => "Campaign Workers' Salaries",
    'TEL' => 'T.V. or Cable Airtime and Production Costs',
    'TRC' => 'Candidate Travel, Lodging, and Meals',
    'TRS' => 'Staff/Spouse Travel, Lodging, and Meals',
    'TSF' => 'Transfer Between Committees of the Same Candidate/sponsor',
    'VOT' => 'Voter Registration',
    'WEB' => 'Information Technology Costs (Internet, E-mail)',
    '' => 'Not Stated'
  }

  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates_by_filer_id =
      candidates.where('"FPPC" IS NOT NULL').index_by { |c| c.FPPC }
    @candidates_by_election_filer_id =
      candidates.where('"FPPC" IS NOT NULL').group_by { |row| row.election_name }.transform_values do |values|
        values.index_by { |c| c.FPPC.to_s }
      end
  end

  def fetch
    # normalization: replace three-letter names with TYPE_DESCRIPTIONS
    TYPE_DESCRIPTIONS.each do |short_name, human_name|
      expenditures_by_candidate_by_type.each do |election_name, values|
        values.each do |filer_id, expenditures_by_type|
          if value = expenditures_by_type.delete(short_name)
            expenditures_by_type[human_name] = value
          end
        end
      end
      supporting_candidate_by_type.each do |election_name, values|
        values.each do |filer_id, expenditures_by_type|
          if value = expenditures_by_type.delete(short_name)
            expenditures_by_type[human_name] = value
          end
        end
      end
      opposing_candidate_by_type.each do |election_name, values|
        values.each do |filer_id, expenditures_by_type|
          if value = expenditures_by_type.delete(short_name)
            expenditures_by_type[human_name] = value
          end
        end
      end
    end

    # save!
    expenditures_by_candidate_by_type.each do |election_name, values|
      values.each do |filer_id, expenditures_by_type|
        candidate = @candidates_by_election_filer_id[election_name][filer_id]
        candidate.save_calculation(:expenditures_by_type, expenditures_by_type)
      end
    end
    supporting_candidate_by_type.each do |election_name, values|
      values.each do |filer_id, supporting_by_type|
        candidate = @candidates_by_election_filer_id[election_name][filer_id]
        candidate.save_calculation(:supporting_by_type, supporting_by_type)
      end
    end
    opposing_candidate_by_type.each do |election_name, values|
      values.each do |filer_id, opposing_by_type|
        candidate = @candidates_by_election_filer_id[election_name][filer_id]
        candidate.save_calculation(:opposing_by_type, opposing_by_type)
      end
    end
  end

  private

  def expenditures_by_candidate_by_type
    @_expenditures_by_candidate_by_type ||= {}.tap do |hash|
      # Include expenses from the 24 hour IE report on FORM 496
      # except those that are already in Schedule E.  Note that
      # Expn_Code is not set in 496 so we cannot just UNION them out.
      results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT election_name, "Filer_ID", COALESCE("Expn_Code", '') as "Expn_Code", SUM("Amount") AS "Total"
        FROM "candidate_e_expenditure"
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        GROUP BY election_name, "Expn_Code", "Filer_ID"
        ORDER BY election_name, "Expn_Code", "Filer_ID"
      SQL

      # 497 does not contain "Expn_Code" making this calculator pretty useless
      # for those contributions.
      # To make the numbers line up closer, we'll bucket those all under "Not
      # Stated".
      late_expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
        SELECT election_name, "Filer_ID", '' AS "Expn_Code", SUM("Amount") AS "Total"
        FROM candidate_497
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        AND "Form_Type" = 'F497P2'
        GROUP BY election_name, "Filer_ID"
        ORDER BY election_name, "Filer_ID"
      SQL

      (results.to_a + late_expenditures.to_a).each do |result|
        filer_id = result['Filer_ID'].to_s
        election_name = result['election_name']

        hash[election_name] ||= {}
        hash[election_name][filer_id] ||= {}
        hash[election_name][filer_id][result['Expn_Code']] = result['Total']
      end

    end
    
  end

  def supporting_candidate_by_type
    @_supporting_candidate_by_type ||= {}.tap do |hash|
      # Include expenses from the 24 hour IE report on FORM 496
      # except those that are already in Schedule E.  Note that
      # Expn_Code is not set in 496 so we use Expn_Dscr instead
      results = ActiveRecord::Base.connection.execute <<-SQL
        WITH combined_expenditures AS (
          SELECT
            election_name,
            "FPPC"::varchar AS "Filer_ID",
            "Expn_Code",
            "Amount"
          FROM candidate_d_expenditure
          WHERE "Sup_Opp_Cd" = 'S'
            AND "Committee_Type" <> 'CTL' AND "Committee_Type" <> 'CAO'
            AND expend.election_name = c.election_name
          UNION ALL
          SELECT
            election_name,
            "FPPC"::varchar AS "Filer_ID",
            "Expn_Dscr" AS "Expn_Code",
            "Amount"
          FROM "candidate_496" AS "outer"
          WHERE "Sup_Opp_Cd" = 'S'
            AND NOT EXISTS (
              SELECT 1 from candidate_d_expenditure AS "inner"
              WHERE "outer"."Filer_ID"::varchar = "inner"."Filer_ID"
                AND "outer"."Exp_Date" = "inner"."Expn_Date"
                AND "outer"."Amount" = "inner"."Amount"
                AND "outer"."Cand_NamL" = "inner"."Cand_NamL"
                AND "outer".election_name = "inner".election_name
            )
            AND "outer".election_name = c.election_name
          )
        SELECT election_name, "Filer_ID", COALESCE("Expn_Code", '') as "Expn_Code", SUM("Amount") AS "Total"
        FROM combined_expenditures
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        GROUP BY election_name, "Expn_Code", "Filer_ID"
        ORDER BY election_name, "Expn_Code", "Filer_ID"
      SQL

      results.to_a.each do |result|
        filer_id = result['Filer_ID'].to_s
        election_name = result['election_name']

        hash[election_name] ||= {}
        hash[election_name][filer_id] ||= {}
        hash[election_name][filer_id][result['Expn_Code']] = result['Total']
      end
    end
  end

  def opposing_candidate_by_type
    @_opposing_candidate_by_type ||= {}.tap do |hash|
      # Include expenses from the 24 hour IE report on FORM 496
      # except those that are already in Schedule E.  Note that
      # Expn_Code is not set in 496 so we use Expn_Dscr instead
      results = ActiveRecord::Base.connection.execute <<-SQL
        WITH combined_opposing_expenditures AS (
          SELECT
            election_name,
            "FPPC"::varchar AS "Filer_ID",
            "Expn_Code",
            "Amount"
          FROM candidate_d_expenditure expend
          WHERE "Sup_Opp_Cd" = 'O'
            AND "Committee_Type" <> 'CTL' AND "Committee_Type" <> 'CAO'
            AND expend.election_name = c.election_name
          UNION ALL
          SELECT
            election_name,
            "FPPC"::varchar AS "Filer_ID",
            "Expn_Dscr" AS "Expn_Code",
            "Amount"
          FROM "candidate_496" AS "outer"
          WHERE "Sup_Opp_Cd" = 'O'
            AND NOT EXISTS (
              SELECT 1 FROM candidate_d_expenditure AS "inner"
              WHERE "outer"."Filer_ID"::varchar = "inner"."Filer_ID"
              AND "outer"."Exp_Date" = "inner"."Expn_Date"
              AND "outer"."Amount" = "inner"."Amount"
              AND "outer"."Cand_NamL" = "inner"."Cand_NamL"
              AND "outer".election_name = "inner".election_name
            )
            AND "outer".election_name = c.election_name
          )
        SELECT election_name, "Filer_ID", COALESCE("Expn_Code", '') as "Expn_Code", SUM("Amount") AS "Total"
        FROM combined_opposing_expenditures
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        GROUP BY election_name, "Expn_Code", "Filer_ID"
        ORDER BY election_name, "Expn_Code", "Filer_ID"
      SQL

      results.to_a.each do |result|
        filer_id = result['Filer_ID'].to_s
        election_name = result['election_name']

        hash[election_name] ||= {}
        hash[election_name][filer_id] ||= {}
        hash[election_name][filer_id][result['Expn_Code']] = result['Total']
      end
    end
  end
end
