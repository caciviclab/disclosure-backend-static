require_relative './environment.rb'

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
        candidates: Candidate.all,
        ballot_measures: Referendum.all,
        committees: Committee.all
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

  # /_data/committees/1229791.json
  build_file("/_data/committees/#{committee['Filer_ID']}.json") do |f|
    f.puts JSON.pretty_generate(committee.data)
  end
end

Election.find_each do |election|
  # /_elections/oakland/2018-11-06.md
  build_file(election.metadata_path) do |f|
    f.puts(YAML.dump(election.metadata))
    f.puts('---')
  end

  # /_data/elections/oakland/2018-11-06.json
  build_file("/_data/elections/#{election.date}.json") do |f|
    f.puts JSON.pretty_generate(election.data)
  end

  election
    .candidates
    .includes(:office_election, :calculations, :election)
    .find_each do |candidate|
      committee = Committee.where(Filer_ID: candidate.FPPC.to_s).first
      contributions = candidate.calculation(:contributions_by_type)
      total_contributions = candidate.calculation(:total_contributions)

      # Calculate the proprtion of small contributions
      unless committee.nil? || contributions.nil? || total_contributions == 0
        total_small = committee.calculation(:total_small_itemized_contributions) +
          contributions['Unitemized']
        candidate.save_calculation(:total_small_contributions, total_small)
        ContributionsByOrigin[election.name] ||= {}
        ContributionsByOrigin[election.name][:small_proportion] ||= []
        ContributionsByOrigin[election.name][:small_proportion].append({
          title: election['title'],
          type: 'office',
          slug: slugify(candidate['Candidate']),
          candidate: candidate['Candidate'],
          proportion: total_small / candidate.calculation(:total_contributions).to_f
        })
      end

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

  # TODO: Move this to the election
  supporting_total = referendum.calculation(:supporting_total) || 0
  opposing_total = referendum.calculation(:opposing_total) || 0
  ContributionsByOrigin[election.name] ||= {}
  ContributionsByOrigin[election.name][:race_totals] ||= []
  ContributionsByOrigin[election.name][:race_totals].append({
    title: "Measure #{referendum['Measure_number']}",
    type: 'referendum',
    slug: title,
    amount: supporting_total + opposing_total
  })
end

build_file('/_data/totals.json') do |f|
  f.puts JSON.pretty_generate(
    Hash[Election.find_each.map do |election|
      totals = ContributionsByOrigin.fetch(election.name, {})
      totals[:largest_independent_expenditures] = election.calculation(:largest_independent_expenditures)

      # Grab top 3 most expensive races
      totals[:most_expensive_races] = totals[:race_totals].sort_by {|v| -v[:amount]}[0..2]
      totals.delete(:race_totals)

      # Get the top 3 small contribution proprtions
      unless totals[:small_proportion].nil?
        totals[:largest_small_proportion] = totals[:small_proportion].sort_by {|v| -v[:proportion]}[0..2]
      end
      totals.delete(:small_proportion)

      [election.name, totals]
    end]
  )
end

build_file('/_data/stats.json') do |f|
  # TODO this should probably be locality-election specific to the date of the bulk data download
  date_processed = File.exist?('downloads/raw/efile_COAK_2020.zip') ?
    File.mtime('downloads/raw/efile_COAK_2020.zip') : Time.now
  f.puts JSON.pretty_generate(
    date_processed: date_processed.to_s
  )
end
