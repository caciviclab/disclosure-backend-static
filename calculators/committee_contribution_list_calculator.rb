class CommitteeContributionListCalculator
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @committees = committees
  end

  def fetch
    results = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT "Filer_ID", "Tran_Amt1", "Tran_Date", "Tran_NamF", "Tran_NamL",
        "Tran_Zip4", "Tran_Occ", "Tran_Emp"
      FROM combined_contributions
      WHERE "Filer_ID" IN (#{filer_ids})
      ORDER BY "Tran_Date" ASC, CONCAT("Tran_NamL", "Tran_NamF"), "Tran_Amt1" ASC
    SQL

    contributions_by_committee = results.each_with_object({}) do |row, hash|
      filer_id = row['Filer_ID'].to_s

      hash[filer_id] ||= []
      hash[filer_id] << row
    end

    @committees.each do |committee|
      filer_id = committee['Filer_ID'].to_s
      sorted = Array(contributions_by_committee[filer_id])
      total_contributions = sorted.reduce(0) do |total, contribution|
        total + contribution['Tran_Amt1']
      end

      committee.save_calculation(:contribution_list, sorted)
      committee.save_calculation(:total_contributions, total_contributions)
    end
  end

  def filer_ids
    @committees.map(&:Filer_ID).map { |f| "'#{f}'::varchar" }.join(',')
  end
end
