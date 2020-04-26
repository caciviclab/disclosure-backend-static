class CommitteeContributionListCalculator
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @committees = committees
    @candidates = candidates
  end

  def fetch
    descriptions = CandidateContributionsByType::TYPE_DESCRIPTIONS
    results = ActiveRecord::Base.connection.execute(<<-SQL)
      WITH all_committees AS (
        SELECT DISTINCT "Filer_ID", "Start_Date", "End_Date"
        FROM committees
        WHERE NOT EXISTS (SELECT * FROM candidates
                          WHERE "FPPC"::varchar = "Filer_ID")
        UNION ALL
        SELECT "FPPC"::varchar AS "Filer_ID", "Start_Date", "End_Date"
        FROM candidates
      )
      SELECT all_contributions."Filer_ID", "Tran_Amt1", "Tran_Date", "Tran_NamF", "Tran_NamL",
        "Tran_Zip4", "Tran_Occ", "Tran_Emp", "Entity_Cd"
      FROM all_contributions
      JOIN all_committees
      ON all_committees."Filer_ID" = all_contributions."Filer_ID"
      AND ("Start_Date" IS NULL OR "Tran_Date" >= "Start_Date")
      AND ("End_Date" IS NULL OR "Tran_Date" <= "End_Date")
      ORDER BY "Tran_Date" ASC, CONCAT("Tran_NamL", "Tran_NamF"), "Tran_Amt1" ASC, "Tran_Emp" ASC
    SQL

    contributions_by_committee = results.each_with_object({}) do |row, hash|
      filer_id = row['Filer_ID'].to_s
      row['Entity_Cd'] = descriptions[row['Entity_Cd']]

      hash[filer_id] ||= []
      hash[filer_id] << row
    end

    [
      [@committees, 'Filer_ID'],
      [@candidates, 'FPPC']
    ].each do |collection, id |
      collection.each do |committee|
        filer_id = committee[id].to_s
        sorted = Array(contributions_by_committee[filer_id])
        total_contributions = 0
        total_small = 0
        sorted.each do |contribution|
          amount = contribution['Tran_Amt1']
          total_contributions += amount
          total_small += amount unless amount  >= 100 || amount <= -100
        end

        committee.save_calculation(:contribution_list, sorted)
        committee.save_calculation(:total_contributions, total_contributions)
        committee.save_calculation(:total_small_itemized_contributions, total_small)
      end
    end
  end

  def filer_ids
    @committees.map(&:Filer_ID).map { |f| "'#{f}'::varchar" }.join(',')
  end
end
