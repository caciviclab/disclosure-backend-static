class CommitteeContributionListCalculator
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @committees = committees
    @candidates = candidates
  end

  def fetch
    descriptions = CandidateContributionsByType::TYPE_DESCRIPTIONS
    results = ActiveRecord::Base.connection.execute(<<-SQL)
      WITH all_committees AS (
        SELECT DISTINCT "Ballot_Measure_Election" as election_name, "Filer_ID", "Start_Date", "End_Date"
        FROM committees
        WHERE NOT EXISTS (SELECT * FROM candidates
                          WHERE "FPPC"::varchar = "Filer_ID")
        UNION ALL
        SELECT election_name, "FPPC"::varchar AS "Filer_ID", "Start_Date", "End_Date"
        FROM candidates
      )
      SELECT election_name, title, date, all_contributions."Filer_ID",
        "Tran_Amt1", "Tran_Date", "Tran_NamF", "Tran_NamL",
        "Tran_Zip4", "Tran_Occ", "Tran_Emp", "Entity_Cd", "Cmte_ID"
      FROM all_contributions
      JOIN all_committees
      ON all_committees."Filer_ID" = all_contributions."Filer_ID"
      AND ("Start_Date" IS NULL OR "Tran_Date" >= "Start_Date")
      AND ("End_Date" IS NULL OR "Tran_Date" <= "End_Date")
      JOIN elections ON election_name = name
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
      collection.each do |committee_or_candidate|
        filer_id = committee_or_candidate[id].to_s
        contributions = Array(contributions_by_committee[filer_id])
        total_contributions = 0
        total_small = 0
        total_by_election = {}
        contributions.each do |contribution|
          amount = contribution['Tran_Amt1']
          total_contributions += amount
          total_small += amount unless amount  >= 100 || amount <= -100
          election_title = contribution['title']
          election_date = contribution['date']
          total_by_election[election_date] ||= [election_title, 0]
          total_by_election[election_date][1] += amount.round(2)
          # Not clear why the round(2) above is not sufficent
          total_by_election[election_date][1] = total_by_election[election_date][1].round(2)

        end
        total_by_election = total_by_election.sort.reverse
        committee_or_candidate.save_calculation(:contribution_list, contributions)
        committee_or_candidate.save_calculation(:contribution_list_total, total_contributions.round(2))
        committee_or_candidate.save_calculation(:total_small_itemized_contributions, total_small.round(2))
        committee_or_candidate.save_calculation(:total_by_election, total_by_election)
      end
    end
  end

  def filer_ids
    @committees.map(&:Filer_ID).map { |f| "'#{f}'::varchar" }.join(',')
  end
end
