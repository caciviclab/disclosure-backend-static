require_relative './environment.rb'
# Office holder accounts don't have an election, skip for now

require 'fileutils'
require 'i18n'
require 'open-uri'

def build_file(filename, &block)
  filename = File.expand_path('../build', __FILE__) + filename
  FileUtils.mkdir_p(File.dirname(filename))
  File.open(filename, 'w', &block)
end

# first, create any missing OfficeElection records for all the offices to assign them IDs
Candidate.select(:Office, :election_name).order(:Office, :election_name).distinct.each do |office|
  OfficeElection
    .where(title: office.Office, election_name: office.election_name)
    .first_or_create
end

# second, process the contribution data
CalculatorRunner
  .new
  .load_calculators('calculators/*')
  .fetch_all!

# This must be before Candidate because candidate also output committee files
# that can duplicate these.
Committee.includes(:calculations).find_each do |committee|
  next if committee['Filer_ID'].nil?
  next if committee['Filer_ID'] =~ /pending/i

  # /_committees/1386416.md
  build_file("/_committees/#{committee.Filer_ID}.md") do |f|
    f.puts(YAML.dump(committee.metadata))
    f.puts('---')
  end

  totals = committee.calculation(:contribution_list_total)
  next if totals.nil?
  lists = committee.calculation(:contribution_list)
  totals.each_pair do | election_name, total |
    election = Election.where(name: election_name).first()
    # Office holder accounts don't have an election, skip for now
    next if election.nil?
    list = lists[election_name]

    # /_data/committees/oakland/2020-03-03/1229791.json
    build_file("/_data/committees" + election.election_path + "#{committee['Filer_ID']}.json") do |f|
      f.puts JSON.pretty_generate(
        {
          total_contributions: total,
          contributions: list,
        }
      )

    end
  end
end

Election.find_each do |election|
  # /_elections/oakland/2018-11-06.md
  build_file(election.metadata_path) do |f|
    f.puts(YAML.dump(election.metadata))
    f.puts('---')
  end

  # /_data/elections/oakland/2018-11-06.json
  build_file("/_data/elections/#{election.locality}/#{election.date}.json") do |f|
    f.puts JSON.pretty_generate(election.data)
  end

  election
    .candidates
    .includes(:office_election, :calculations, :election)
    .find_each do |candidate|
      filename = slugify(candidate['Candidate'])

      # /_data/candidates/oakland/2016-11-06/libby-schaaf.json
      build_file("/_data/candidates/#{election.locality}/#{election.date}/#{filename}.json") do |f|
        f.puts JSON.pretty_generate(candidate.data)
      end

      # /_candidates/abel-guillen.md
      build_file("/_candidates/#{election.locality}/#{election.date}/#{slugify(candidate.Candidate)}.md") do |f|
        f.puts(YAML.dump(candidate.metadata))
        f.puts('---')
      end

      # /_committees/123456.md
      build_file("/_committees/#{candidate.FPPC}.md") do |f|
        f.puts(YAML.dump(Committee.from_candidate(candidate).metadata))
        f.puts('---')
      end

      totals = candidate.calculation(:contribution_list_total)
      next if totals.nil?
      lists = candidate.calculation(:contribution_list)
      total = totals[election.name]
      list = lists[election.name]

      # /_data/committees/oakland/2020-03-03/1229791.json
      build_file("/_data/committees" + election.election_path + "#{candidate.FPPC}.json") do |f|
        f.puts JSON.pretty_generate(
          {
            total_contributions: total,
            contributions: list,
          }
        )
      end

      build_file("/_data/committees/#{candidate.FPPC}.json") do |f|
        f.puts JSON.pretty_generate(candidate.committee_data)
      end
    end


  # /_office_elections/oakland/2018-11-06/city-auditor.md
  election.office_elections.find_each do |office_election|
    build_file("/_office_elections/#{election.locality}/#{election.date}/#{slugify(office_election.title)}.md") do |f|
      f.puts(YAML.dump(office_election.metadata))
      f.puts('---')
    end
  end
end

Referendum.includes(:calculations).find_each do |referendum|
  title = slugify(referendum['Short_Title'])
  election = referendum.election

  if election.nil?
    $stderr.puts "MISSING ELECTION:"
    $stderr.puts "  Election Name: #{election.name}"
    $stderr.puts '  Add it to ELECTIONS global in process.rb'
    next
  end

  # /_referendums/oakland/2018-11-06/oakland-childrens-initiative.md
  build_file("/_referendums/#{election.locality}/#{election.date}/#{title}.md") do |f|
    f.puts(YAML.dump(referendum.metadata))
    f.puts('---')
    f.puts(referendum['Summary'])
  end

  # /_data/referendum_supporting/oakland/2018-11-06/oakland-childrens-initiative.json
  build_file("/_data/referendum_supporting/#{election.locality}/#{election.date}/#{title}.json") do |f|
    f.puts JSON.pretty_generate(referendum.supporting_data)
  end

  # /_data/referendum_opposing/oakland/2018-11-06/oakland-childrens-initiative.json
  build_file("/_data/referendum_opposing/#{election.locality}/#{election.date}/#{title}.json") do |f|
    f.puts JSON.pretty_generate(referendum.opposing_data)
  end
end

build_file('/_data/totals.json') do |f|
  f.puts JSON.pretty_generate(Hash[Election.find_each.map { |election| [election.name, election.data] }])
end

build_file('/_data/stats.json') do |f|
  # TODO this should probably be locality-election specific to the date of the bulk data download
  date_processed = File.exist?('downloads/raw/efile_COAK_2020.zip') ?
    File.mtime('downloads/raw/efile_COAK_2020.zip') : Time.now
  f.puts JSON.pretty_generate(
    date_processed: date_processed.to_s
  )
end
