class CandidateContributionsByType
  TYPE_DESCRIPTIONS = {
    'IND' => 'Individual',
    'COM' => 'Committee',
    'OTH' => 'Other (includes Businesses)',
    'SLF' => 'Self Funding'
  }

  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates_by_filer_id =
      candidates.where('"FPPC" IS NOT NULL').index_by { |c| c.FPPC }
  end

  def fetch
    # normalization: lump in "SCC" (small contributor committee) with "COM"
    contributions_by_candidate_by_type.each do |filer_id, contributions_by_type|
      if small_contributor_committee = contributions_by_type.delete('SCC')
        contributions_by_type['COM'] ||= 0
        contributions_by_type['COM'] += small_contributor_committee.to_f
      end
    end

    # normalization: fetch unitemized totals and add it as a bucket too
    unitemized_contributions_by_candidate.each do |filer_id, unitemized_contributions|
      contributions_by_candidate_by_type[filer_id] ||= {}
      contributions_by_candidate_by_type[filer_id]['Unitemized'] = unitemized_contributions.to_f
    end

    # normalization: replace three-letter names with TYPE_DESCRIPTIONS
    TYPE_DESCRIPTIONS.each do |short_name, human_name|
      contributions_by_candidate_by_type.each do |filer_id, contributions_by_type|
        if value = contributions_by_type.delete(short_name)
          contributions_by_type[human_name] = value
        end
      end
    end

    # save!
    contributions_by_candidate_by_type.each do |filer_id, contributions_by_type|
      candidate = @candidates_by_filer_id[filer_id.to_i]
      candidate.save_calculation(:contributions_by_type, contributions_by_type)
    end
  end

  private

  def contributions_by_candidate_by_type
    @_contributions_by_candidate_by_type ||= {}.tap do |hash|
      # NOTE: We remove duplicate transactions on 497 that are also reported on
      # Schedule A during a preprocssing script. (See
      # `./../remove_duplicate_transactionts.sh`)
      monetary_results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT
          "Filer_ID",
          CASE
            WHEN "FPPC" IS NULL THEN "Entity_Cd"
            ELSE 'SLF'
          END AS "Cd",
          SUM("Tran_Amt1") AS "Total"
        FROM candidate_contributions
        LEFT OUTER JOIN "oakland_candidates"
          ON "FPPC"::varchar = "Filer_ID"
          AND (
            -- Schedules A & C have a "Tran_Self" column we can use, but 497 does not.
            -- So, we instead do a name match of the receipient. And of course, sometimes
            --   the candidate's name in the recipient field of the donation is reported
            --   slightly differently so we have an Aliases table to handle those cases.
            LOWER("Candidate") = LOWER(CONCAT("Tran_NamF", ' ', "Tran_NamL"))
            OR LOWER("Aliases") LIKE LOWER(CONCAT('%', "Tran_NamF", ' ', "Tran_NamL", '%'))
          )
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        GROUP BY "Cd", "Filer_ID"
        ORDER BY "Cd", "Filer_ID";
      SQL

      monetary_results.to_a.each do |result|
        filer_id = result['Filer_ID'].to_s

        hash[filer_id] ||= {}
        hash[filer_id][result['Cd']] ||= 0
        hash[filer_id][result['Cd']] += result['Total']
      end
    end
  end

  def unitemized_contributions_by_candidate
    @_unitemized_contributions_by_candidate ||= {}.tap do |hash|
      results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT "Filer_ID", SUM("Amount_A") AS "Amount_A" FROM "Summary"
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
          AND "Form_Type" = 'A' AND "Line_Item" = '2'
        GROUP BY "Filer_ID"
        ORDER BY "Filer_ID"
      SQL

      hash.merge!(Hash[results.map { |row| row.values_at('Filer_ID', 'Amount_A') }])
    end
  end
end
