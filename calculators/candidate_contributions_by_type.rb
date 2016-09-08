class CandidateContributionsByType
  TYPE_DESCRIPTIONS = {
    'IND' => 'Individual',
    'COM' => 'Committee',
    'OTH' => 'Other (includes Businesses)',
  }

  def initialize(candidates: [])
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
      monetary_results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT "Filer_ID", "Entity_Cd", SUM("Tran_Amt1") AS "Total"
        FROM "efile_COAK_2016_A-Contributions"
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        GROUP BY "Entity_Cd", "Filer_ID";
      SQL

      in_kind_results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT "Filer_ID", "Entity_Cd", SUM("Tran_Amt1") AS "Total"
        FROM "efile_COAK_2016_C-Contributions"
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        GROUP BY "Entity_Cd", "Filer_ID";
      SQL

      (monetary_results.to_a + in_kind_results.to_a).each do |result|
        filer_id = result['Filer_ID'].to_s

        hash[filer_id] ||= {}
        hash[filer_id][result['Entity_Cd']] ||= 0
        hash[filer_id][result['Entity_Cd']] += result['Total']
      end
    end
  end

  def unitemized_contributions_by_candidate
    @_unitemized_contributions_by_candidate ||= {}.tap do |hash|
      results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT "Filer_ID", "Amount_A" FROM "efile_COAK_2016_Summary"
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
          AND "Form_Type" = 'A' AND "Line_Item" = '2'
      SQL

      hash.merge!(Hash[results.map { |row| row.values_at('Filer_ID', 'Amount_A') }])
    end
  end
end
