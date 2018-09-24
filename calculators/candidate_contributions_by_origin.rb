class CandidateContributionsByOrigin

  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates_by_filer_id =
      candidates.where('"FPPC" IS NOT NULL').index_by { |c| c.FPPC }
  end

  def fetch
      monetary_results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT "Filer_ID",
        CASE
          WHEN TRIM(LOWER("Tran_City")) = LOWER(location) THEN CONCAT('Within ', location)
          WHEN UPPER("Tran_State") = 'CA' THEN 'Within California'
          ELSE 'Out of State'
        END AS locale,
        SUM("Tran_Amt1") AS total
        FROM candidate_contributions
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        GROUP BY "Filer_ID", locale
      SQL

      hash = {}
      monetary_results.to_a.each do |result|
        filer_id = result['Filer_ID'].to_s

        hash[filer_id] ||= {}
        hash[filer_id][result['locale']] ||= 0
        hash[filer_id][result['locale']] += result['total']
        election = @candidates_by_filer_id[filer_id.to_i].election_name
        ContributionsByOrigin[election] ||= {}
        ContributionsByOrigin[election][result['locale']] ||= 0
        ContributionsByOrigin[election][result['locale']] += result['total']
      end
    hash.each do |filer_id, contributions_by_local|
      candidate = @candidates_by_filer_id[filer_id.to_i]
      candidate.save_calculation(:contributions_by_origin, contributions_by_local)
    end
  end
end
