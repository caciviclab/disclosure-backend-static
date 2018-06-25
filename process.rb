require_relative './environment.rb'

require 'fileutils'
require 'open-uri'

# map of election_name => { hash including date }
ELECTIONS = {
  'sf-2016' => { date: '2016-11-08' },
  'oakland-2016' => { date: '2016-11-08' },

  'sf-june-2018' => { date: '2018-06-05' },
  'oakland-june-2018' => { date: '2018-06-05' },

  'sf-2018' => { date: '2018-11-06' },
  'oakland-2018' => { date: '2018-11-06' },
  'berkeley-2018' => { date: '2018-11-06' },
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
