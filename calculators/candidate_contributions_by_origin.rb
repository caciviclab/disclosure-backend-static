class CandidateContributionsByOrigin

  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates_by_filer_id =
      candidates.where('"FPPC" IS NOT NULL').index_by { |c| c.FPPC }
    @candidates_by_election_filer_id =
      candidates.where('"FPPC" IS NOT NULL').group_by { |row| row.election_name }.transform_values do |values|
        values.index_by { |c| c.FPPC.to_s }
      end
  end

  def fetch
    monetary_results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT election_name,
        "Filer_ID",
        CASE
          WHEN TRIM(LOWER("Tran_City")) = LOWER(location) THEN CONCAT('Within ', location)
          WHEN UPPER("Tran_State") = 'CA' THEN 'Within California'
          ELSE 'Out of State'
        END AS locale,
        SUM("Tran_Amt1") AS total
        FROM candidate_contributions
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        GROUP BY election_name, "Filer_ID", locale
    SQL

    hash = {}
    monetary_results.to_a.each do |result|
      election_name = result['election_name']
      filer_id = result['Filer_ID'].to_s
      locale = result['locale']
      total = result['total']

      hash[election_name] ||= {}
      hash[election_name][filer_id] ||= {}
      hash[election_name][filer_id][locale] ||= 0
      hash[election_name][filer_id][locale] += total
    end
    hash.each do |election_name, values|
      values.each do |filer_id, contributions_by_locale|
        candidate = @candidates_by_election_filer_id[election_name][filer_id]
        candidate.save_calculation(:contributions_by_origin, contributions_by_locale)
      end
    end
  end
end
