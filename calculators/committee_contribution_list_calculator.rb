class CommitteeContributionListCalculator
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @committees = committees
    @candidates = candidates
  end

  def fetch
    descriptions = CandidateContributionsByType::TYPE_DESCRIPTIONS
    results = ActiveRecord::Base.connection.execute(<<-SQL)
      WITH all_committees AS (
        SELECT DISTINCT "Filer_ID", "Ballot_Measure_Election" as election_name, "Start_Date", "End_Date"
        FROM committees
        WHERE NOT EXISTS (SELECT * FROM candidates
                          WHERE "FPPC"::varchar = "Filer_ID")
        UNION ALL
        SELECT "FPPC"::varchar AS "Filer_ID", election_name, "Start_Date", "End_Date"
        FROM candidates
      )
      SELECT all_contributions."Filer_ID", election_name, "Tran_Amt1", "Tran_Date",
        "Tran_NamF", "Tran_NamL", "Tran_Zip4", "Tran_Occ", "Tran_Emp", "Entity_Cd"
      FROM all_contributions
      JOIN all_committees
      ON all_committees."Filer_ID" = all_contributions."Filer_ID"
      AND ("Start_Date" IS NULL OR "Tran_Date" >= "Start_Date")
      AND ("End_Date" IS NULL OR "Tran_Date" <= "End_Date")
      ORDER BY "Tran_Date" ASC, CONCAT("Tran_NamL", "Tran_NamF"), "Tran_Amt1" ASC, "Tran_Emp" ASC
    SQL

    contributions_by_committee = results.each_with_object({}) do |row, hash|
      filer_id = row['Filer_ID'].to_s
      election = row['election_name']
      row['Entity_Cd'] = descriptions[row['Entity_Cd']]

      hash[filer_id] ||= {}
      hash[filer_id][election] ||= []
      hash[filer_id][election] << row
    end

    [
      [@committees, 'Filer_ID', 'Ballot_Measure_Election'],
      [@candidates, 'FPPC', 'election_name']
    ].each do |collection, id, name |
      collection.each do |committee_or_candidate|
        filer_id = committee_or_candidate[id].to_s
        election = committee_or_candidate[name]
        filer_list = contributions_by_committee[filer_id]
        next if filer_list.nil? || filer_list[election].nil?
        sorted = Array(filer_list[election])
        total_contributions = 0
        total_small = 0
        sorted.each do |contribution|
          amount = contribution['Tran_Amt1']
          total_contributions += amount
          total_small += amount unless amount  >= 100 || amount <= -100
        end
        list = committee_or_candidate.calculation(:contribution_list) || {}
        list[election] = sorted
        committee_or_candidate.save_calculation(:contribution_list, list)
        totals = committee_or_candidate.calculation(:contribution_list_total) || {}
        totals[election] = total_contributions
        committee_or_candidate.save_calculation(:contribution_list_total, totals)
        smalls = committee_or_candidate.calculation(:contribution_list_total) || {}
        smalls[election] = total_small
        committee_or_candidate.save_calculation(:total_small_itemized_contributions, smalls)
      end
    end
  end

  def filer_ids
    @committees.map(&:Filer_ID).map { |f| "'#{f}'::varchar" }.join(',')
  end
end
