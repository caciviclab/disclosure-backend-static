# TODO:
# /ballot/:id/disclosure_summary
# /referendum/:id/supporting
# /referendum/:id/opposing
require 'json'

require 'fileutils'
require 'pg'

def build_file(filename, &block)
  filename = File.expand_path('../build', __FILE__) + filename
  FileUtils.mkdir_p(filename) unless File.exist?(filename)
  File.open(File.join(filename, 'index.json'), 'w', &block)
end

$id = 1
$candidates_by_id = {}
$ballot_measures_by_id = {}
$offices_by_id = {}
def get_id(record)
  if record[:office]
    $id += 1
    $offices_by_id[$id] = record[:office]
    return $id
  elsif record['Candidate']
    $id += 1
    $candidates_by_id[$id] = record
    return $id
  elsif record['Measure_number']
    $id += 1
    $ballot_measures_by_id[$id] = record
    return $id
  end
end

$db = PG.connect(dbname: 'disclosure-backend')

OAKLAND_LOCALITY_ID = 2

build_file('/locality/search') do |f|
  f.puts JSON.generate([{ name: 'Oakland', type: 'city', id: OAKLAND_LOCALITY_ID }])
end

build_file("/locality/#{OAKLAND_LOCALITY_ID}") do |f|
  f.puts JSON.generate([{ name: 'Oakland', type: 'city', id: OAKLAND_LOCALITY_ID }])
end

candidates = $db.exec('SELECT * FROM oakland_candidates').to_a
office_ballot_items = candidates.group_by { |c| c['Office'] }.map do |office, rows|
  next unless office
  office_election_id = get_id(office: office)

  {
    id: office_election_id,
    contest_type: 'Office',
    name: office,
    candidates: rows.map do |row|
      first_name, last_name = row['Candidate'].split(' ', 2) # Probably wrong!

      {
        id: get_id(row),
        name: row['Candidate'],

        # fields for /candidate/:id
        photo_url: row['Photo'],
        website_url: row['Website'],
        twitter_url: row['Twitter'],
        first_name: first_name,
        last_name: last_name,
        ballot_item: office_election_id,
        office_election: office_election_id,
      }
    end
  }
end
referendum_ballot_items = $db.exec('SELECT * FROM oakland_referendums').map do |row|
  next unless row['Short_Title']
  {
    id: get_id(row),
    contest_type: 'Referendum',
    name: row['Short_Title'],

    # fields for /referendum/:id
    title: row['Short_Title'],
    summary: row['Summary'],
    number: row['Measure_number'],
  }
end.compact

%W[
  /ballot/1
  /locality/#{OAKLAND_LOCALITY_ID}/current_ballot
].each do |filename|
  build_file(filename) do |f|
    f.puts JSON.generate({
      id: 1,
      ballot_items: office_ballot_items + referendum_ballot_items,
      date: '2016-11-06',
      locality_id: OAKLAND_LOCALITY_ID,
    })
  end
end

office_ballot_items.each do |item|
  build_file("/office_election/#{item[:id]}") do |f|
    f.puts JSON.generate(item.merge(ballot_id: 1))
  end

  item[:candidates].each do |candidate|
    build_file("/candidate/#{candidate[:id]}/supporting") do |f|
      f.puts JSON.generate(candidate.merge(
        contributions_received: 1234,
      ))
    end

    build_file("/candidate/#{candidate[:id]}/opposing") do |f|
      f.puts JSON.generate(candidate.merge(
        contributions_received: 4567,
      ))
    end

    build_file("/candidate/#{candidate[:id]}") do |f|
      f.puts JSON.generate(candidate)
    end
  end
end

referendum_ballot_items.each do |item|
  build_file("/referendum/#{item[:id]}") do |f|
    f.puts JSON.generate(item.merge(ballot_id: 1))
  end

  build_file("/referendum/#{item[:id]}/supporting") do |f|
    f.puts JSON.generate(item.merge(
      contributions_received: 1234,
    ))
  end

  build_file("/referendum/#{item[:id]}/opposing") do |f|
    f.puts JSON.generate(item.merge(
      contributions_received: 4567,
    ))
  end
end
