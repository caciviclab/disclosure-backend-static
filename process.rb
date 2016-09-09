# TODO:
# /ballot/:id/disclosure_summary

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
      )
      .fetch
  rescue NameError => ex
    if ex.message =~ /#{class_name}/
      $stderr.puts "ERROR: Undefined constant #{class_name}, expected it to be "\
        "defined in #{calculator_file}"
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
  build_file("/candidate/#{candidate.id}") do |f|
    f.puts candidate.to_json
  end

  build_file("/candidate/#{candidate.id}/supporting") do |f|
    f.puts JSON.pretty_generate(candidate.as_json.merge(
      contributions_received: candidate.calculation(:total_contributions).try(:to_f),
      total_contributions: candidate.calculation(:total_contributions).try(:to_f),
      total_expenditures: candidate.calculation(:total_expenditures).try(:to_f),
      total_loans_received: candidate.calculation(:total_loans_received).try(:to_f),
      contributions_by_type: candidate.calculation(:contributions_by_type) || {},
    ))
  end

  build_file("/candidate/#{candidate.id}/opposing") do |f|
    f.puts JSON.pretty_generate(candidate.as_json.merge(
      contributions_received: 4567,
    ))
  end
end

OaklandReferendum.find_each do |referendum|
  build_file("/referendum/#{referendum.id}") do |f|
    f.puts JSON.pretty_generate(referendum.as_json.merge(ballot_id: 1))
  end

  build_file("/referendum/#{referendum.id}/supporting") do |f|
    f.puts JSON.pretty_generate(referendum.as_json.merge(
      money_supporting: 1234,
      money_supporting_by_region: {
        within_oakland: 123,
        within_california: 111,
        out_of_state: 222,
      }
    ))
  end

  build_file("/referendum/#{referendum.id}/opposing") do |f|
    f.puts JSON.pretty_generate(referendum.as_json.merge(
      money_opposing: 3333,
      money_opposing_by_region: {
        within_oakland: 123,
        within_california: 111,
        out_of_state: 222,
      }
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
