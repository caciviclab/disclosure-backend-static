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
    @candidates_by_filer_id_election =
      candidates.where('"FPPC" IS NOT NULL').index_by { |c| "#{c.FPPC}.#{c.election_name}"  }
  end

  def fetch
    # normalization: lump in "SCC" (small contributor committee) with "COM"
    contributions_by_candidate_by_type.each do |filer_id_election, contributions_by_type|
      if small_contributor_committee = contributions_by_type.delete('SCC')
        contributions_by_type['COM'] ||= 0
        contributions_by_type['COM'] += small_contributor_committee.to_f
      end
    end

    # normalization: fetch unitemized totals and add it as a bucket too
    unitemized_contributions_by_candidate.each do |filer_id_election, unitemized_contributions|
      contributions_by_candidate_by_type[filer_id_election] ||= {}
      contributions_by_candidate_by_type[filer_id_election]['Unitemized'] = unitemized_contributions.to_f
    end

    # normalization: replace three-letter names with TYPE_DESCRIPTIONS
    TYPE_DESCRIPTIONS.each do |short_name, human_name|
      contributions_by_candidate_by_type.each do |filer_id_election, contributions_by_type|
        if value = contributions_by_type.delete(short_name)
          contributions_by_type[human_name] = value
        end
      end
    end

    # save!
    contributions_by_candidate_by_type.each do |filer_id_election, contributions_by_type|
      candidate = @candidates_by_filer_id_election[filer_id_election]
      candidate.save_calculation(:contributions_by_type, contributions_by_type)

      # Calculate the total of small contributions
      total_small = candidate.calculation(:total_small_itemized_contributions) +
        (contributions_by_type['Unitemized'] || 0)
      candidate.save_calculation(:total_small_contributions, total_small)
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
          "Filer_ID",
          candidate_contributions.election_name,
          CASE
            WHEN "FPPC" IS NULL THEN "Entity_Cd"
            ELSE 'SLF'
          END AS "Cd",
          SUM("Tran_Amt1") AS "Total"
        FROM candidate_contributions
        LEFT OUTER JOIN "candidates"
          ON "FPPC"::varchar = "Filer_ID"
          AND candidates.election_name = candidate_contributions.election_name
          AND (
            -- Schedules A & C have a "Tran_Self" column we can use, but 497 does not.
            -- So, we instead do a name match of the receipient. And of course, sometimes
            --   the candidate's name in the recipient field of the donation is reported
            --   slightly differently so we have an Aliases table to handle those cases.
            LOWER("Candidate") = LOWER(CONCAT("Tran_NamF", ' ', "Tran_NamL"))
            OR LOWER("Aliases") LIKE LOWER(CONCAT('%', "Tran_NamF", ' ', "Tran_NamL", '%'))
          )
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
        GROUP BY "Cd", "Filer_ID", candidate_contributions.election_name
        ORDER BY "Cd", "Filer_ID", candidate_contributions.election_name;
      SQL

      monetary_results.to_a.each do |result|
        filer_id_election = "#{result['Filer_ID']}.#{result['election_name']}"

        hash[filer_id_election] ||= {}
        hash[filer_id_election][result['Cd']] ||= 0
        hash[filer_id_election][result['Cd']] += result['Total']
      end
    end
  end

  def unitemized_contributions_by_candidate
    @_unitemized_contributions_by_candidate ||= {}.tap do |hash|
      results = ActiveRecord::Base.connection.execute <<-SQL
        SELECT "Filer_ID" || '.' || election_name AS filer_id_election, SUM("Amount_A") AS "Amount_A" FROM "Summary"
        JOIN candidates
          ON "FPPC"::varchar = "Filer_ID"
        JOIN elections
          ON name = election_name
          AND EXTRACT('Year' FROM date) = EXTRACT('Year' FROM "Thru_Date")
        WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
          AND "Form_Type" = 'A' AND "Line_Item" = '2'
        GROUP BY "Filer_ID", election_name
        ORDER BY "Filer_ID", election_name
      SQL

      hash.merge!(Hash[results.map { |row| row.values_at('filer_id_election', 'Amount_A') }])
    end
  end
end
