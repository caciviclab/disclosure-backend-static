# TODO:
# /ballot/:id/disclosure_summary
require 'json'
module ::JSON
  class << self
    # HACK: replace the implementation of `JSON.generate` so our models are
    # serialized pretty by default. Probably could do this better with a
    # subclass of ActiveSupport::Serialization::JSONEncoder or whatever.
    alias_method :old_generate, :generate
    alias_method :generate, :pretty_generate
  end
end

require 'active_record'
Dir.glob('models/*.rb').each { |f| load f }

require 'fileutils'
require 'open-uri'
ActiveRecord::Base.establish_connection 'postgresql:///disclosure-backend'

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

OAKLAND_LOCALITY_ID = 2

build_file('/locality/search') do |f|
  f.puts JSON.pretty_generate([{ name: 'Oakland', type: 'city', id: OAKLAND_LOCALITY_ID }])
end

build_file("/locality/#{OAKLAND_LOCALITY_ID}") do |f|
  f.puts JSON.pretty_generate([{ name: 'Oakland', type: 'city', id: OAKLAND_LOCALITY_ID }])
end

office_ballot_items = OfficeElection.find_each.map do |office_election|
  {
    id: office_election.id,
    contest_type: 'Office',
    name: office_election.name,
    candidates: office_election.candidates.map(&:as_json),
  }
end
referendum_ballot_items = OaklandReferendum.find_each.map do |referendum|
  {
    id: referendum.id,
    contest_type: 'Referendum',
    name: referendum['Short_Title'],

    # fields for /referendum/:id
    title: referendum['Short_Title'],
    summary: referendum['Summary'],
    number: referendum['Measure_number'],
  }
end.compact

%W[
  /ballot/1
  /locality/#{OAKLAND_LOCALITY_ID}/current_ballot
].each do |filename|
  build_file(filename) do |f|
    f.puts({
      id: 1,
      ballot_items: (office_ballot_items + referendum_ballot_items),
      date: '2016-11-06',
      locality_id: OAKLAND_LOCALITY_ID,
    }.to_json)
  end
end

office_ballot_items.each do |item|
  build_file("/office_election/#{item[:id]}") do |f|
    f.puts JSON.pretty_generate(item.merge(ballot_id: 1))
  end
end

OaklandCandidate.includes(:office_election).find_each do |candidate|
  build_file("/candidate/#{candidate.id}") do |f|
    f.puts candidate.to_json
  end

  build_file("/candidate/#{candidate.id}/supporting") do |f|
    f.puts JSON.pretty_generate(candidate.as_json.merge(
      contributions_received: 1234,
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
      contributions_received: 1234,
    ))
  end

  build_file("/referendum/#{referendum.id}/opposing") do |f|
    f.puts JSON.pretty_generate(referendum.as_json.merge(
      contributions_received: 4567,
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
