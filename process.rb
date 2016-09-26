require_relative './environment.rb'

require 'fileutils'
require 'open-uri'

def build_file(filename, &block)
  filename = File.expand_path('../build', __FILE__) + filename
  FileUtils.mkdir_p(filename) unless File.exist?(filename)
  File.open(File.join(filename, 'index.json'), 'w', &block)
end

# first, create OfficeElection records for all the offices to assign them IDs
OaklandCandidate.distinct(:Office).pluck(:Office).each do |office|
  OfficeElection
    .where(name: office)
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

build_file('/locality/search') do |f|
  f.puts JSON.pretty_generate([{ name: 'Oakland', type: 'city', id: OAKLAND_LOCALITY_ID }])
end

build_file("/locality/#{OAKLAND_LOCALITY_ID}") do |f|
  f.puts JSON.pretty_generate([{ name: 'Oakland', type: 'city', id: OAKLAND_LOCALITY_ID }])
end

%W[
  /ballot/1
  /locality/#{OAKLAND_LOCALITY_ID}/current_ballot
].each do |filename|
  build_file(filename) do |f|
    f.puts({
      id: 1,
      ballot_items: (
        OfficeElection.all.map(&:as_json) +
        OaklandReferendum.all.map(&:as_json)
      ),
      date: '2016-11-06',
      locality_id: OAKLAND_LOCALITY_ID,
    }.to_json)
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
    /candidate/#{candidate.id}/supporting
    /candidate/#{candidate.id}/opposing
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
  build_file("/committee/#{committee['Filer_ID']}") do |f|
    f.puts committee.to_json
  end

  build_file("/committee/#{committee['Filer_ID']}/contributions") do |f|
    f.puts JSON.pretty_generate(committee.calculation(:contribution_list) || [])
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
    ))
  end
end

build_file('/docs/api-docs/') do |f|
  spec = JSON.parse(open('http://admin.caciviclab.org/docs/api-docs/').read)
  spec['basePath'] = 'http://disclosure-backend-static.f.tdooner.com/docs/api-docs/'
  f.puts JSON.pretty_generate(spec)

  spec['apis'].each do |api_resource|
    build_file("/docs/api-docs/#{api_resource['path']}") do |f2|
      resource_spec = JSON.parse(open("http://admin.caciviclab.org/docs/api-docs/#{api_resource['path']}").read)
      resource_spec['basePath'] = 'http://disclosure-backend-static.f.tdooner.com'
      f2.puts JSON.pretty_generate(resource_spec)
    end
  end
end
