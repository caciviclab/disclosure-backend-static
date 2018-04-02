require_relative './environment.rb'

require 'fileutils'
require 'open-uri'

def build_file(filename, &block)
  filename = File.expand_path('../build', __FILE__) + filename
  FileUtils.mkdir_p(filename) unless File.exist?(filename)
  File.open(File.join(filename, 'index.json'), 'w', &block)
end

# first, create OfficeElection records for all the offices to assign them IDs
OaklandCandidate.select(:Office, :election_name).order(:Office, :election_name).distinct.each do |office|
  OfficeElection
    .where(name: office.Office, election_name: office.election_name)
    .first_or_create
end

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

# third, write everything out to the build files
OAKLAND_LOCALITY_ID = 2
ELECTIONS = [
  { id: 1, date: '2016-11-08', election_name: 'oakland-2016', is_current: true },
  { id: 2, date: '2018-11-06', election_name: 'oakland-2018' },
]

build_file('/locality/search') do |f|
  f.puts JSON.pretty_generate([{ name: 'Oakland', type: 'city', id: OAKLAND_LOCALITY_ID }])
end

build_file("/locality/#{OAKLAND_LOCALITY_ID}") do |f|
  f.puts JSON.pretty_generate([{ name: 'Oakland', type: 'city', id: OAKLAND_LOCALITY_ID }])
end

ELECTIONS.each do |election|
  candidates = OfficeElection.where(election_name: election[:election_name])
  referendums = OaklandReferendum.where(election_name: election[:election_name])
  files = [
    "/ballot/#{election[:id]}",
    ("/locality/#{OAKLAND_LOCALITY_ID}/current_ballot" if election[:is_current])
  ].compact

  files.each do |filename|
    build_file(filename) do |f|
      f.puts({
        id: 1,
        ballot_items: (
          candidates.map(&:as_json) +
          referendums.map(&:as_json)
        ),
        date: election[:date],
        locality_id: OAKLAND_LOCALITY_ID,
      }.to_json)
    end
  end
end

OfficeElection.find_each do |office_election|
  build_file("/office_election/#{office_election.id}") do |f|
    f.puts JSON.pretty_generate(office_election.as_json.merge(ballot_id: 1))
  end
end

OaklandCandidate.includes(:office_election, :calculations).find_each do |candidate|
  %W[
    /candidate/#{candidate.id}
  ].each do |candidate_filename|
    build_file(candidate_filename) do |f|
      #
      # To add a field to one of these endpoints, add it to the '#as_json'
      # method in models/oakland_candidate.rb
      #
      f.puts candidate.to_json
    end
  end
end

OaklandCommittee.includes(:calculations).find_each do |committee|
  next if committee['Filer_ID'].nil?
  next if committee['Filer_ID'] =~ /pending/i

  build_file("/committee/#{committee['Filer_ID']}") do |f|
    f.puts committee.to_json
  end

  build_file("/committee/#{committee['Filer_ID']}/contributions") do |f|
    f.puts JSON.pretty_generate(committee.calculation(:contribution_list) || [])
  end
  build_file("/committee/#{committee['Filer_ID']}/opposing") do |f|
    f.puts JSON.pretty_generate(committee.calculation(:opposition_list) || [])
  end
end

OaklandReferendum.find_each do |referendum|
  build_file("/referendum/#{referendum.id}") do |f|
    f.puts JSON.pretty_generate(referendum.as_json.merge(ballot_id: 1))
  end

  build_file("/referendum/#{referendum.id}/supporting") do |f|
    f.puts JSON.pretty_generate(referendum.as_json.merge(
      supporting_organizations:
        referendum.calculation(:supporting_organizations) || [],
      total_contributions:
        referendum.calculation(:supporting_total) || [],
      contributions_by_region:
        referendum.calculation(:supporting_locales) || [],
      contributions_by_type:
        referendum.calculation(:supporting_type) || [],
    ))
  end

  build_file("/referendum/#{referendum.id}/opposing") do |f|
    f.puts JSON.pretty_generate(referendum.as_json.merge(
      opposing_organizations:
        referendum.calculation(:opposing_organizations) || [],
      total_contributions:
        referendum.calculation(:opposing_total) || [],
      contributions_by_region:
        referendum.calculation(:opposing_locales) || [],
      contributions_by_type:
        referendum.calculation(:opposing_type) || [],
    ))
  end
end

build_file('/stats') do |f|
  f.puts JSON.pretty_generate(
    date_processed: TZInfo::Timezone.get('America/Los_Angeles').now.to_date,
  )
end
