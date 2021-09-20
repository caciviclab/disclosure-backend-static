#!/usr/bin/env ruby
# Usage:
#   ruby search_index.rb
# So that the data retured are ordered properly some fields are mapped
# into common field names. Otherwise the ordering will tend to segragate
# by record type.
#
require_relative './environment.rb'

require 'algoliasearch'
require 'optparse'
require 'soda/client'

def contributors_to_committee(name, id, election)
  contrib = Committee.where(["\"Filer_ID\" = ?", id]).first
    &.calculation(:contribution_list)
  return nil if contrib.nil?
  return contrib.map do |contributor|
    {
      type: :contributor,
      c_name: contributor['Tran_NamF'] ?
          (contributor['Tran_NamF'] + ' ' + contributor['Tran_NamL']).squish
         : contributor['Tran_NamL'],
      amount: contributor['Tran_Amt1'],
      committee_name: name,
      committee_id: id,
      election_slug: election.name,
      election_location: election.location,
      election_date: election.date,
      election_title: election.title,
    }
  end
end

client = Algolia::Client.new(
  application_id: ENV['ALGOLIASEARCH_APPLICATION_ID'],
  api_key: ENV['ALGOLIASEARCH_API_KEY'],
)

if !client.list_indexes()['items'].include?('election')
  puts "Initializing index: election"
end

index = client.init_index('election')

oak_client = SODA::Client.new({:domain => "data.oklandca.gov", :app_token => "4FYL4zxMOncsLeANaeDzP455z"})
oak_response = oak_client.get("https://data.oaklandca.gov/resource/f4dq-mk8d").body
charity_data = oak_response.map do |donation|
  {
    type: :donation,
    name: donation.official,
    office_title: donation.office,
    c_name: donation.payor,
    location: donation.payor_city,
    payee: donation.payee,
    amount: donation.amount.to_i,
    # merge this field with the election_date so sorting is more consistent
    election_date: donation.payment_date[0,10],
    description: donation.description,
    url: if donation.url.nil?
           nil
         else
           donation.url["url"].to_s
         end,
  }
end
puts "Indexing #{charity_data.length} behested donations"

candidate_data = Candidate.includes(:election, :office_election).map do |candidate|
  {
    type: :candidate,
    name: candidate['Candidate'],
    office_label: candidate.office_election.label,
    office_title: candidate.office_election.title,
    office_slug: slugify(candidate.office_election.title),
    candidate_slug: slugify(candidate['Candidate']),
    election_slug: candidate.election.name,
    election_location: candidate.election.location,
    election_date: candidate.election.date,
    election_title: candidate.election.title,
  }
end
puts "Indexing #{candidate_data.length} Candidates..."

iec_data = []
iec_contrib  = []
contributor_data = []
Candidate.includes(:election, :committee, :office_election).find_each do |candidate|
  next if candidate.committee.nil?
  list = candidate.committee.calculation(:contribution_list).map do |contributor|
    {
      type: :contributor,
      c_name: contributor['Tran_NamF'] ?
          (contributor['Tran_NamF'] + ' ' + contributor['Tran_NamL']).squish
         : contributor['Tran_NamL'],
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

  [
    [:support_list, "Supporting"],
    [:opposition_list, "Opposing"],
  ].each do |calculation, supporting|
    list = candidate.calculation(calculation)
    next if list.nil?
    list.each do |iec|
      iec_data +=
        [{
          type: :iec,
          committee_name: iec['Filer_NamL'],
          committee_id: iec['Filer_ID'],
          supporting: supporting,
          amount: iec['Total'],
          name: candidate['Candidate'],
          candidate_slug: slugify(candidate['Candidate']),
          office_label: candidate.office_election.label,
          office_title: candidate.office_election.title,
          office_slug: slugify(candidate.office_election.title),
          election_slug: candidate.election.name,
          election_location: candidate.election.location,
          election_date: candidate.election.date,
          election_title: candidate.election.title,
        }]
      contrib = contributors_to_committee(iec['Filer_NamL'], iec['Filer_ID'], candidate.election)
      next if contrib.nil?
      iec_contrib += contrib
    end
  end
end

# A committee can support/oppose multiple candidates
# Delete duplicates, not too efficient but keeps the code simple.
iec_contrib.uniq!

puts "Indexing #{contributor_data.length} Contributors..."
puts "Indexing #{iec_data.length} Independent Committies..."
puts "Indexing #{iec_contrib.length} IC Contributors..."

referendum_data = []
ballot_committees = []
ballot_contrib = []
Referendum.includes(:election).find_each do |referendum|
  referendum_data += [{
    type: :referendum,
    title: referendum['Short_Title'],
    measure: "Measure: " + referendum['Measure_number'],
    slug: slugify(referendum['Short_Title']),
    election_slug: referendum.election.name,
    election_location: referendum.election.location,
    election_date: referendum.election.date,
    election_title: referendum.election.title,
  }]
  [
    [:supporting_organizations, "Supporting"],
    [:opposing_organizations, "Opposing"],
  ].each do |calculation, supporting|
    list = referendum.calculation(calculation)
    next if list.nil?

    list.each do |committee|
      ballot_committees += [{
        type: :committee,
        committee_name: committee['name'],
        committee_id: committee['id'],
        supporting: supporting,
        amount: committee['amount'],
        title: referendum['Short_Title'],
        measure: "Measure: " + referendum['Measure_number'],
        slug: slugify(referendum['Short_Title']),
        election_slug: referendum.election.name,
        election_location: referendum.election.location,
        election_date: referendum.election.date,
        election_title: referendum.election.title,
      }]
      contrib = contributors_to_committee(committee['name'], committee['id'], referendum.election)
      next if contrib.nil?
      ballot_contrib += contrib
    end
  end
end

ballot_contrib.uniq!

puts "Indexing #{referendum_data.length} Referendums..."
puts "Indexing #{ballot_committees.length} Ballot Committees..."
puts "Indexing #{ballot_contrib.length} Ballot Contributors..."

committee_data = []
committee_contrib = []
Committee.where(Make_Active: 'YES').find_each do |committee|
  next if ballot_committees.any? {|c| c[:committee_id] == committee['Filer_ID'] }
  next if iec_data.any? {|c| c[:committee_id] == committee['Filer_ID'] }
  election = Election.where(name: committee['Ballot_Measure_Election']).first
  committee_data += [{
    type: :committee,
    committee_name: committee['Filer_NamL'],
    committee_id: committee['Filer_ID'],
    amount: committee.calculation(:contribution_list_total),
    election_slug: election.name,
    election_location: election.location,
    election_date: election.date,
    election_title: election.title,
  }]
  contrib = contributors_to_committee(committee['Filer_NamL'], committee['Filer_ID'], election)
  next if contrib.nil?
  committee_contrib += contrib
end
puts "Indexing #{committee_data.length} Active Committees..."
puts "Indexing #{committee_contrib.length} Active Committee Contributors..."


all_data = ballot_contrib + ballot_committees + referendum_data +
  contributor_data + candidate_data + iec_data + iec_contrib +
  committee_data + committee_contrib + charity_data
puts "total records: #{all_data.length}"

# Test code so we don't burn all of our allocation on Aloglia
if ENV['ALGOLIASEARCH_SAMPLE_DATA']
  sampled_data = []
  i = 0
  all_data.each do |data|
    i += 1
    next if i.modulo(4) != 0
    sampled_data += [data]
  end
  puts "sampled records: #{sampled_data.length}"
  index.replace_all_objects(sampled_data)
else
  index.replace_all_objects(all_data)
end
