require_relative './environment.rb'

require 'fileutils'
require 'open-uri'

# map of election_name => { hash including date }
ELECTIONS = {
  'sf-2016' => { date: '2016-11-08', title: 'San Francisco November 8th, 2016 Election' },
  'oakland-2016' => { date: '2016-11-08', title: 'Oakland November 8th, 2016 Election' },

  'sf-june-2018' => { date: '2018-06-05', title: 'San Francisco June 5th, 2018 Election'  },
  'oakland-june-2018' => { date: '2018-06-05', title: 'Oakland June 5th, 2018 Election' },

  'sf-2018' => { date: '2018-11-06', title: 'San Francisco November 6th, 2018 Election'  },
  'oakland-2018' => { date: '2018-11-06', title: 'Oakland November 6th, 2018 Election' },
  'berkeley-2018' => { date: '2018-11-06', title: 'Berkeley November 6th, 2018 Election'  },
}

def build_file(filename, &block)
  filename = File.expand_path('../build', __FILE__) + filename
  FileUtils.mkdir_p(File.dirname(filename))
  File.open(filename, 'w', &block)
end

# keep this logic in-sync with the frontend
# (text || '').toLowerCase().replace(/[\._~!$&'()+,;=@]+/g, '').replace(/[^a-z0-9-]+/g, '-');
def slugify(word)
  (word || '').downcase.gsub(/[\._~!$&'()+,;=@]+/, '').gsub(/[^a-z0-9-]+/, '-')
end

# Sort like:
# 1. Mayor
# 2. City Council ...
# 3. City ...
# 4. School Board
#
# If multiple offices match the same regex they are sorted alphabetically (i.e.
# "School Board District 1", then "School Board District 2")
SORT_PATTERNS = [
  /mayor/i,
  /city council/i,
  /city /i,
  /ousd/i,
]
def sort_office_elections(office_elections)
  office_elections
    .group_by { |office| SORT_PATTERNS.find_index { |p| office =~ p } || Float::INFINITY }
    .sort_by { |k, _v| k }
    .map { |_k, v| v.sort }
    .flatten
end

# first, create OfficeElection records for all the offices to assign them IDs
OaklandCandidate.select(:Office, :election_name).order(:Office, :election_name).distinct.each do |office|
  OfficeElection
    .where(name: office.Office, election_name: office.election_name)
    .first_or_create
end

# Accumulate totals by orgin while processing Candidate and Referendums
ContributionsByOrigin = {}

# second, process the contribution data
#   load calculators dynamically, assume each one defines a class given by its
#   filename. E.g. calculators/foo_calculator.rb would define "FooCalculator"
Dir.glob('calculators/*').each do |calculator_file|
  basename = File.basename(calculator_file.chomp('.rb'))
  class_name = ActiveSupport::Inflector.classify(basename)
  begin
    calculator_class = class_name.constantize
    calculator_class
      .new(
        candidates: OaklandCandidate.all,
        ballot_measures: OaklandReferendum.all,
        committees: OaklandCommittee.all
      )
      .fetch
  rescue NameError => ex
    if ex.message =~ /uninitialized constant #{class_name}/
      $stderr.puts "ERROR: Undefined constant #{class_name}, expected it to be "\
        "defined in #{calculator_file}"
      puts ex.message
      exit 1
    else
      raise
    end
  end
end

# /_ballots/oakland/2018-11-06.md
ELECTIONS.each do |election_name, election|
  locality, _time = election_name.split('-', 2)
  office_elections = sort_office_elections(
    OaklandCandidate.where(election_name: election_name).pluck(:Office).uniq
  )
  referendums = OaklandReferendum.where(election_name: election_name).pluck(:Short_Title).uniq
  ballot_name = "/_ballots/#{locality}/#{election[:date]}.md"

  build_file(ballot_name) do |f|
    f.puts(YAML.dump(
      'title' => election[:title],
      'locality' => locality,
      'election' => election[:date],
      'office_elections' => office_elections.map do |office|
        "_office_elections/#{locality}/#{election[:date]}/#{slugify(office)}.md"
      end,
      'referendums' => referendums.map do |title|
        "_referendums/#{locality}/#{election[:date]}/#{slugify(title)}.md"
      end,
    ))
    f.puts('---')
  end

  # /_office_elections/oakland/2018-11-06/city-auditor.md
  office_elections.each do |office|
    build_file("/_office_elections/#{locality}/#{election[:date]}/#{slugify(office)}.md") do |f|
      candidates = OaklandCandidate.where(Office: office, election_name: election_name).pluck(:Candidate)

      f.puts(YAML.dump(
        'title' => office,
        'candidates' => candidates.map { |name| slugify(name) },
        'ballot' => ballot_name[1..-1],
      ))
      f.puts('---')
    end
  end
end

# /_data/candidates/libby-schaaf.json
OaklandCandidate.includes(:office_election, :calculations).find_each do |candidate|
  filename = slugify(candidate['Candidate'])
  build_file("/_data/candidates/#{filename}.json") do |f|
    f.puts candidate.to_json
  end
end

# /_data/contributions/1229791.json
OaklandCommittee.includes(:calculations).find_each do |committee|
  next if committee['Filer_ID'].nil?
  next if committee['Filer_ID'] =~ /pending/i

  build_file("/_data/committees/#{committee['Filer_ID']}.json") do |f|
    f.puts JSON.pretty_generate(contributions: committee.calculation(:contribution_list) || [])
  end
end

OaklandReferendum.includes(:calculations).find_each do |referendum|
  locality, _year = referendum.election_name.split('-', 2)
  election = ELECTIONS[referendum.election_name]
  title = slugify(referendum['Short_Title'])

  if election.nil?
    $stderr.puts "MISSING ELECTION:"
    $stderr.puts "  Election Name: #{referendum.election_name}"
    $stderr.puts '  Add it to ELECTIONS global in process.rb'
    next
  end

  # /_referendums/oakland/2018-11-06/oakland-childrens-initiative.md
  build_file("/_referendums/#{locality}/#{election[:date]}/#{title}.md") do |f|
    f.puts(YAML.dump(
      'locality' => locality,
      'election' => election[:date],
      'title' => referendum['Short_Title'],
      'number' => referendum['Measure_number']
    ))
    f.puts('---')
    f.puts(referendum['Summary'])
  end

  # /_data/referendum_supporting/oakland/2018-11-06/oakland-childrens-initiative.json
  build_file("/_data/referendum_supporting/#{locality}/#{election[:date]}/#{title}.json") do |f|
    f.puts JSON.pretty_generate(referendum.as_json.merge(
      supporting_organizations: referendum.calculation(:supporting_organizations) || [],
      total_contributions: referendum.calculation(:supporting_total) || [],
      contributions_by_region: referendum.calculation(:supporting_locales) || [],
      contributions_by_type: referendum.calculation(:supporting_type) || [],
    ))
  end

  # /_data/referendum_opposing/oakland/2018-11-06/oakland-childrens-initiative.json
  build_file("/_data/referendum_opposing/#{locality}/#{election[:date]}/#{title}.json") do |f|
    f.puts JSON.pretty_generate(referendum.as_json.merge(
      opposing_organizations: referendum.calculation(:opposing_organizations) || [],
      total_contributions: referendum.calculation(:opposing_total) || [],
      contributions_by_region: referendum.calculation(:opposing_locales) || [],
      contributions_by_type: referendum.calculation(:opposing_type) || [],
    ))
  end
end

build_file('/_data/totals.json') do |f|
  f.puts JSON.pretty_generate(Hash[ContributionsByOrigin.sort])
end

build_file('/_data/stats.json') do |f|
  f.puts JSON.pretty_generate(
    date_processed: TZInfo::Timezone.get('America/Los_Angeles').now.to_date,
  )
end
