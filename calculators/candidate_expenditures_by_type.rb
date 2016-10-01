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
  end

  def fetch
    # normalization: replace three-letter names with TYPE_DESCRIPTIONS
    TYPE_DESCRIPTIONS.each do |short_name, human_name|
      expenditures_by_candidate_by_type.each do |filer_id, expenditures_by_type|
        if value = expenditures_by_type.delete(short_name)
          expenditures_by_type[human_name] = value
        end
      end
      opposing_candidate_by_type.each do |filer_id, expenditures_by_type|
        if value = expenditures_by_type.delete(short_name)
          expenditures_by_type[human_name] = value
        end
      end
    end

    # save!
    expenditures_by_candidate_by_type.each do |filer_id, expenditures_by_type|
      candidate = @candidates_by_filer_id[filer_id.to_i]
      candidate.save_calculation(:expenditures_by_type, expenditures_by_type)
    end
    opposing_candidate_by_type.each do |filer_id, expenditures_by_type|
      candidate = @candidates_by_filer_id[filer_id.to_i]
      candidate.save_calculation(:opposing_by_type, expenditures_by_type)
    end
  end

  private

  def expenditures_by_candidate_by_type
    @_expenditures_by_candidate_by_type ||= {}.tap do |hash|
      # Include expenses from the 24 hour IE report on FORM 496
      # except those that are already in Schedule E.  Note that
      # Expn_Code is not set in 496 so we cannot just UNION them out.
      results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT "Filer_ID", "Expn_Code", SUM("Amount") AS "Total"
        FROM
          (
          SELECT "Filer_ID", "Expn_Code", "Amount"
          FROM "efile_COAK_2016_E-Expenditure"
          UNION ALL
          SELECT "FPPC"::varchar AS "Filer_ID", '' AS "Expn_Code", "Amount"
          FROM "efile_COAK_2016_496" AS "outer", "oakland_candidates"
          WHERE "Sup_Opp_Cd" = 'S'
          AND lower("Candidate") = lower(trim(concat("Cand_NamF", ' ', "Cand_NamL")))
          AND NOT EXISTS (SELECT 1 from "efile_COAK_2016_E-Expenditure" AS "inner"
              WHERE "outer"."Filer_ID"::varchar = "inner"."Filer_ID"
              AND "outer"."Exp_Date" = "inner"."Expn_Date"
              AND "outer"."Amount" = "inner"."Amount"
              AND "outer"."Cand_NamL" = "inner"."Cand_NamL")
          ) U
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        GROUP BY "Expn_Code", "Filer_ID"
        ORDER BY "Expn_Code", "Filer_ID"
      SQL

      # 497 does not contain "Expn_Code" making this calculator pretty useless
      # for those contributions.
      # To make the numbers line up closer, we'll bucket those all under "Not
      # Stated".
      late_expenditures = ActiveRecord::Base.connection.execute(<<-SQL)
        SELECT "Filer_ID", '' AS "Expn_Code", SUM("Amount") AS "Total"
        FROM "efile_COAK_2016_497"
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        AND "Form_Type" = 'F497P2'
        GROUP BY "Filer_ID"
        ORDER BY "Filer_ID"
      SQL

      (results.to_a + late_expenditures.to_a).each do |result|
        hash[result['Filer_ID']] ||= {}
        hash[result['Filer_ID']][result['Expn_Code']] = result['Total']
      end
    end
  end


  def opposing_candidate_by_type
    @_opposing_candidate_by_type ||= {}.tap do |hash|
      # Include expenses from the 24 hour IE report on FORM 496
      # except those that are already in Schedule E.  Note that
      # Expn_Code is not set in 496 so we cannot just UNION them out.
      results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT "Filer_ID", "Expn_Code", SUM("Amount") AS "Total"
        FROM
          (SELECT "FPPC"::varchar AS "Filer_ID", "Expn_Code", "Amount"
          FROM "efile_COAK_2016_E-Expenditure", "oakland_candidates"
          WHERE "Sup_Opp_Cd" = 'O'
          AND lower("Candidate") = lower(trim(concat("Cand_NamF", ' ', "Cand_NamL")))
          AND "Committee_Type" <> 'CTL' AND "Committee_Type" <> 'CAO'
          UNION ALL
          SELECT "FPPC"::varchar AS "Filer_ID", '' AS "Expn_Code", "Amount"
          FROM "efile_COAK_2016_496" AS "outer", "oakland_candidates"
          WHERE "Sup_Opp_Cd" = 'O'
          AND lower("Candidate") = lower(trim(concat("Cand_NamF", ' ', "Cand_NamL")))
          AND NOT EXISTS (SELECT 1 from "efile_COAK_2016_E-Expenditure" AS "inner"
              WHERE "outer"."Filer_ID"::varchar = "inner"."Filer_ID"
              AND "outer"."Exp_Date" = "inner"."Expn_Date"
              AND "outer"."Amount" = "inner"."Amount"
              AND "outer"."Cand_NamL" = "inner"."Cand_NamL")
          ) U
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        GROUP BY "Expn_Code", "Filer_ID"
        ORDER BY "Expn_Code", "Filer_ID"
      SQL

      results.to_a.each do |result|
        hash[result['Filer_ID']] ||= {}
        hash[result['Filer_ID']][result['Expn_Code']] = result['Total']
      end
    end
  end
end
