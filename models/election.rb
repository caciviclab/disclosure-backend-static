class Election < ActiveRecord::Base
  include HasCalculations

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
    {
      'total_contributions_by_source' => {
        'From Within Oakland' => 0.55,
        'In-State' => 0.055,
        'Out of State' => 0.05,
      },
      'top_spenders' => [
        {
          'name' => 'Jeff Bezos',
          'total_contributions' => 555,
        },
        {
          'name' => 'Elon Musk',
          'total_contributions' => 55,
        },
        {
          'name' => 'Travis Kalanick',
          'total_contributions' => 5,
        },
      ],
      'candidates_with_most_small_contributions' => [
        {
          'name' => 'Zhao Liu',
          'slug' => 'stephanie-dominguez-walton',
          'office_title' => 'Mayor of Oakland',
          'office_slug' => 'city-council-district-1',
          'small_contribution_percent' => 0.55,
        },
        {
          'name' => 'Sally Trotski',
          'slug' => 'stephanie-dominguez-walton',
          'office_title' => 'City Council District 1',
          'office_slug' => 'city-council-district-1',
          'small_contribution_percent' => 0.55,
        },
        {
          'name' => 'Peter San Marco',
          'slug' => 'stephanie-dominguez-walton',
          'office_title' => 'City Council District 1',
          'office_slug' => 'city-council-district-1',
          'small_contribution_percent' => 0.55,
        },
      ],
      'total_contributions' => 5_555_555,
      'contributions_by_type' => {
        'Committee' => 55_555.55,
        'Individual' => 5_555.55,
        'Unitemized' => 5_550.55,
        'Self Funding' => 5_500.55,
        'Other (includes businesses)' => 5_000.55,
      },
      'most_expensive_races' => [
        {
          'title' => 'Mayor',
          'type' => 'office',
          'slug' => 'mayor',
          'amount' => 5555555
        },
        {
          'title' => 'City Council District 2',
          'type' => 'office',
          'slug' => 'city-council-district-2',
          'amount' => 5555555
        },
        {
          'title' => 'City Council District 6',
          'type' => 'office',
          'slug' => 'city-council-district-6',
          'amount' => 555555
        },
      ],
      'largest_independent_expenditures' => [
        {
          'Filer_NamL' => 'NATIONAL ASSOCIATION OF FIVERS',
          'Total_Amount' => 555000,
          'election_name' => 'oakland-2020'
        },
        {
          'Filer_NamL' => 'CALIFORNIA ASSOCIATION OF FIVE ISSUES MOBILIZATION PAC',
          'Total_Amount' => 55005,
          'election_name' => 'oakland-2020'
        }
      ],
    }
  end
end
