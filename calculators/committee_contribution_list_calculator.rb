class CommitteeContributionListCalculator
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @committees = committees
    @candidates = candidates
  end

  def fetch
    results = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT all_contributions."Filer_ID", "Tran_Amt1", "Tran_Date", "Tran_NamF", "Tran_NamL",
        "Tran_Zip4", "Tran_Occ", "Tran_Emp"
      FROM all_contributions
      JOIN (
        SELECT DISTINCT "Filer_ID", "Start_Date", "End_Date" FROM oakland_committees
        WHERE NOT EXISTS (SELECT * FROM oakland_candidates
                          WHERE "FPPC"::varchar = "Filer_ID")
        UNION ALL
        SELECT "FPPC"::varchar AS "Filer_ID", "Start_Date", "End_Date" FROM oakland_candidates
      ) committees
      ON committees."Filer_ID" = all_contributions."Filer_ID"
      AND ("Start_Date" IS NULL OR "Tran_Date" >= "Start_Date")
      AND ("End_Date" IS NULL OR "Tran_Date" <= "End_Date")
      ORDER BY "Tran_Date" ASC, CONCAT("Tran_NamL", "Tran_NamF"), "Tran_Amt1" ASC
    SQL

    contributions_by_committee = results.each_with_object({}) do |row, hash|
      filer_id = row['Filer_ID'].to_s

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
        total_contributions = sorted.reduce(0) do |total, contribution|
          total + contribution['Tran_Amt1']
        end

        committee.save_calculation(:contribution_list, sorted)
        committee.save_calculation(:total_contributions, total_contributions)
      end
    end
  end

  def filer_ids
    @committees.map(&:Filer_ID).map { |f| "'#{f}'::varchar" }.join(',')
  end
end
