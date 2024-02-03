class CandidateContributionsByType
  TYPE_DESCRIPTIONS = {
    'IND' => 'Individual',
    'COM' => 'Committee',
    'SCC' => 'Small Contribution Committee',
    'OTH' => 'Other (includes Businesses)',
    'SLF' => 'Self Funding'
  }

  def self.dependencies
    [
      { model: Committee, calculation: :total_small_itemized_contributions },
      { model: Candidate, calculation: :total_small_itemized_contributions },
    ]
  end

  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates_by_filer_id =
      candidates.where('"FPPC" IS NOT NULL').index_by { |c| c.FPPC }
    @candidates_by_election_filer_id =
      candidates.where('"FPPC" IS NOT NULL').group_by { |row| row.election_name }.transform_values do |values|
        values.index_by { |c| c.FPPC.to_s }
      end
  end

  def fetch
    # normalization: lump in "SCC" (small contributor committee) with "COM"
    contributions_by_candidate_by_type.each do |election_name, values|
      values.each do |filer_id, contributions_by_type|
        if small_contributor_committee = contributions_by_type.delete('SCC')
          contributions_by_type['COM'] ||= 0
          contributions_by_type['COM'] += small_contributor_committee.to_f
        end
      end
    end

    # normalization: fetch unitemized totals and add it as a bucket too
    unitemized_contributions_by_candidate.each do |election_name, values|
      contributions_by_candidate_by_type[election_name] ||= {}
      values.each do |filer_id, unitemized_contributions|
        contributions_by_candidate_by_type[election_name][filer_id] ||= {}
        contributions_by_candidate_by_type[election_name][filer_id]['Unitemized'] = unitemized_contributions.to_f
      end
    end

    # normalization: replace three-letter names with TYPE_DESCRIPTIONS
    TYPE_DESCRIPTIONS.each do |short_name, human_name|
      contributions_by_candidate_by_type.each do |election_name, values|
        values.each do |filer_id, contributions_by_type|
          if value = contributions_by_type.delete(short_name)
            contributions_by_type[human_name] = value
          end
        end
      end
    end

    # save!
    contributions_by_candidate_by_type.each do |election_name, values|
      values.each do |filer_id, contributions_by_type|
        candidate = @candidates_by_election_filer_id[election_name][filer_id]
        candidate.save_calculation(:contributions_by_type, contributions_by_type)

        # Calculate the total of small contributions
        total_small = candidate.calculation(:total_small_itemized_contributions) +
          (contributions_by_type['Unitemized'] || 0)
        candidate.save_calculation(:total_small_contributions, total_small)
      end
    end
  end

  private

  def contributions_by_candidate_by_type
    @_contributions_by_candidate_by_type ||= {}.tap do |hash|
      # NOTE: We remove duplicate transactions on 497 that are also reported on
      # Schedule A during a preprocssing script. (See
      # `./../remove_duplicate_transactions.sh`)
      monetary_results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT
          cc.election_name,
          "Filer_ID",
          CASE
            WHEN "FPPC" IS NULL THEN "Entity_Cd"
            ELSE 'SLF'
          END AS "Cd",
          SUM("Tran_Amt1") AS "Total"
        FROM candidate_contributions cc
        LEFT OUTER JOIN "candidates"
          ON "FPPC"::varchar = "Filer_ID"
          AND candidates.election_name = cc.election_name
          AND (
            -- Schedules A & C have a "Tran_Self" column we can use, but 497 does not.
            -- So, we instead do a name match of the receipient. And of course, sometimes
            --   the candidate's name in the recipient field of the donation is reported
            --   slightly differently so we have an Aliases table to handle those cases.
            LOWER("Candidate") = LOWER(CONCAT("Tran_NamF", ' ', "Tran_NamL"))
            OR LOWER("Aliases") LIKE LOWER(CONCAT('%', "Tran_NamF", ' ', "Tran_NamL", '%'))
          )
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        GROUP BY cc.election_name, "Cd", "Filer_ID"
        ORDER BY cc.election_name, "Cd", "Filer_ID";
      SQL

      monetary_results.to_a.each do |result|
        filer_id = result['Filer_ID'].to_s
        election_name = result['election_name']

        hash[election_name] ||= {}
        hash[election_name][filer_id] ||= {}
        hash[election_name][filer_id][result['Cd']] ||= 0
        hash[election_name][filer_id][result['Cd']] += result['Total']
      end
    end
  end

  def unitemized_contributions_by_candidate
    @_unitemized_contributions_by_candidate ||= {}.tap do |hash|
      results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT election_name, "Filer_ID", SUM("Amount_A") AS "Amount_A" FROM "candidate_summary"
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
          AND ( "Form_Type" = 'A' OR "Form_Type" = 'C')
          AND "Line_Item" = '2'
        GROUP BY "Filer_ID"
        ORDER BY "Filer_ID"
      SQL

      hash.merge!(results.group_by { |row| row['election_name'].itself }.transform_values do |values|
        Hash[values.map{ |subrow| subrow.values_at('Filer_ID', 'Amount_A')}]
      end)
    end
  end
end
