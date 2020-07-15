require_relative './environment.rb'

require 'algoliasearch'

client = Algolia::Client.new(
  application_id: ENV['ALGOLIASEARCH_APPLICATION_ID'],
  api_key: ENV['ALGOLIASEARCH_API_KEY'],
)

if !client.list_indexes()['items'].include?('election')
  puts "Initializing index: election"
end

index = client.init_index('election')

candidate_data = Candidate.includes(:election, :office_election).map do |candidate|
  {
    type: :candidate,
    name: candidate['Candidate'],
    office_label: candidate.office_election.label,
    office_title: candidate.office_election.title,
    office_slug: slugify(candidate.office_election.title),
    slug: slugify(candidate['Candidate']),
    election_slug: candidate.election.name,
    election_location: candidate.election.location,
    election_date: candidate.election.date,
    election_title: candidate.election.title,
  }
end
puts "Indexing #{candidate_data.length} Candidates..."
index.add_objects(candidate_data)

contributor_data = []
Candidate.includes(:election, :committee, :office_election).find_each do |candidate|
  next if candidate.committee.nil?
  list = candidate.committee.calculation(:contribution_list).map do |contributor|
    {
      type: :contributor,
      first_name: contributor['Tran_NamF'],
      last_name: contributor['Tran_NamL'],
      amount: contributor['Tran_Amt1'],
      name: candidate['Candidate'],
      candidate_slug: slugify(candidate['Candidate']),
      office_label: candidate.office_election.label,
      office_title: candidate.office_election.title,
      office_slug: slugify(candidate.office_election.title),
      election_slug: candidate.election.name,
      election_location: candidate.election.location,
      election_date: candidate.election.date,
      election_title: candidate.election.title,
    }
  end
  unless list.nil?
    contributor_data += list
  end
end
puts "Indexing #{contributor_data.length} Contributors..."
index.add_objects(contributor_data)

referendum_data = Referendum.includes(:election).map do |referendum|
  {
    type: :referendum,
    title: referendum['Short_Title'],
    slug: slugify(referendum['Short_Title']),
    election_slug: referendum.election.name,
    election_location: referendum.election.location,
    election_date: referendum.election.date,
    election_title: referendum.election.title,
  }
end
puts "Indexing #{referendum_data.length} Referendums..."
index.add_objects(referendum_data)
