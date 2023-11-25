require 'set'

class TotalContributionsCalculator
  def initialize(candidates: [], ballot_measures: [], committees: [])
    @candidates_by_filer_id =
      candidates
        .find_all { |c| c.FPPC.present? }
        .index_by { |c| c.FPPC.to_s }
    @candidates_by_election_filer_id =
      candidates.find_all { |c| c.FPPC.present? }.group_by { |row| row.election_name }.transform_values do |values|
        values.index_by { |c| c.FPPC.to_s }
      end
  end

  def fetch
    contributions_by_election_filer_id = {}

    summary_results = ActiveRecord::Base.connection.execute <<-SQL
      SELECT election_name, "Filer_ID", SUM("Amount_A") AS "Amount_A"
      FROM candidate_summary
      WHERE "Form_Type" = 'F460'
      AND "Line_Item" = '5'
      GROUP BY election_name, "Filer_ID"
      ORDER BY election_name, "Filer_ID"
    SQL

    summary_results.each do |result|
      election_name = result['election_name']
      filer_id = result['Filer_ID'].to_s
      contributions_by_election_filer_id[election_name] ||= {}
      contributions_by_election_filer_id[election_name][filer_id] ||= 0
      contributions_by_election_filer_id[election_name][filer_id] += result['Amount_A'].to_f
    end

    # NOTE: We remove duplicate transactions on 497 that are also reported on
    # Schedule A during a preprocssing script. (See
    # `./../remove_duplicate_transactionts.sh`)
    late_results = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT election_name, "Filer_ID", SUM("Amount") AS "Total"
      FROM "candidate_497"
      WHERE "Filer_ID" IN ('#{@candidates_by_filer_id.keys.join "','"}')
      AND "Form_Type" = 'F497P1'
      GROUP BY election_name, "Filer_ID"
      ORDER BY election_name, "Filer_ID"
    SQL

    late_results.each do |result|
      election_name = result['election_name']
      filer_id = result['Filer_ID'].to_s
      contributions_by_election_filer_id[election_name] ||= {}
      contributions_by_election_filer_id[election_name][filer_id] ||= 0
      contributions_by_election_filer_id[election_name][filer_id] += result['Total'].to_f
    end

    contributions_by_election_filer_id.each do |election_name, values|
      values.each do |filer_id, total_contributions|
        candidate = @candidates_by_election_filer_id[election_name][filer_id]
        candidate.save_calculation(:total_contributions, total_contributions.round(2))
      end
    end
  end
end
