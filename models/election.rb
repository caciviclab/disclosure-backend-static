class Election < ActiveRecord::Base
  include HasCalculations

  has_many :candidates, foreign_key: :election_name, primary_key: :name
  has_many :office_elections, foreign_key: :election_name, primary_key: :name
  has_many :referendums, foreign_key: :election_name, primary_key: :name

  def locality
    name.split('-', 2).first
  end

  def metadata_path
    "/_elections/#{locality}/#{date}.md"
  end

  def metadata
    {
      'title' => title,
      'election_id' => name,
      'locality' => locality,
      'election' => date.to_s,
      'office_elections' => office_elections.group_by(&:label).map do |label, office_elections|
        {
          'label' => label,
          'items' => office_elections.map do |office_election|
            "_office_elections/#{locality}/#{date}/#{slugify(office_election.title)}.md"
          end
        }.compact
      end,
      'referendums' => referendums.map do |referendum|
        "_referendums/#{locality}/#{date}/#{slugify(referendum.Short_Title)}.md"
      end,
    }
  end

  def data
      round_numbers(
      total_contributions: calculation(:total_contributions).try(:to_f),
      total_contributions_by_source: calculation(:contributions_by_origin) || {},
      contributions_by_type: calculation(:contributions_by_type) || {},
      most_expensive_races: calculation(:most_expensive_races) || {},
      largest_small_proportion: calculation(:largest_small_proportion) || [],
      largest_independent_expenditures: calculation(:largest_independent_expenditures) || {},
      top_contributors: calculation(:top_contributors) || [],
      top_contributors_for_offices: calculation(:top_contributors_for_offices) || [],
      top_contributors_for_measures: calculation(:top_contributors_for_measures) || [],
      top_spenders: calculation(:top_spenders) || [],
      top_spenders_for_offices: calculation(:top_spenders_for_offices) || [],
      top_spenders_for_measures: calculation(:top_spenders_for_measures) || [],
      )
  end
end
