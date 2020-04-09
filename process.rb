require_relative './environment.rb'

require 'fileutils'
require 'i18n'
require 'open-uri'

# map of election_name => Election object
ELECTIONS = Election.all.index_by(&:name)

def build_file(filename, &block)
  filename = File.expand_path('../build', __FILE__) + filename
  FileUtils.mkdir_p(File.dirname(filename))
  File.open(filename, 'w', &block)
end

# keep this logic in-sync with the frontend (Jekyll's slugify filter)
# https://github.com/jekyll/jekyll/blob/035ea729ff5668dfc96e7f56a86d214e5a633291/lib/jekyll/utils.rb#L204
# We add transliteration to convert non-latin characters to ascii, especially
# for candidate names. e.g. Guillén -> guillen.
def slugify(word)
  I18n.transliterate(word || '')
    .downcase.gsub(/[^a-z0-9-]+/, '-')
end

# Sort like:
# 1. Mayor
# 2. City Council ...
# 3. City ...
# 4. School Board
#
# If multiple offices match the same regex they are sorted alphabetically (i.e.
# "School Board District 1", then "School Board District 2")
SORT_PATTERNS = [
  /mayor/i,
  /city /i,
  /city council/i,
  /ousd/i,
]

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

ELECTIONS.each do |election_name, election|
  election_path = "/_elections/#{election.locality}/#{election.date}.md"

  # /_elections/oakland/2018-11-06.md
  build_file(election_path) do |f|
    f.puts(YAML.dump(election.metadata))
    f.puts('---')
  end

  # /_data/elections/oakland/2018-11-06.json
  build_file("/_data/elections/#{election.date}.json") do |f|
    f.puts JSON.pretty_generate(election.data)
  end

  Candidate
    .where(election_name: election_name)
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
        ContributionsByOrigin[election_name] ||= {}
        ContributionsByOrigin[election_name][:small_proportion] ||= []
        ContributionsByOrigin[election_name][:small_proportion].append({
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
    end


  # /_office_elections/oakland/2018-11-06/city-auditor.md
  OfficeElection.where(election_name: election_name).find_each do |office_election|
    build_file("/_office_elections/#{election.locality}/#{election.date}/#{slugify(office_election.title)}.md") do |f|
      candidates =
        Candidate
          .where(Office: office_election.title, election_name: election_name)
          .sort_by do |candidate|
            [-1 * (candidate.calculation(:total_contributions) || 0.0), candidate.Candidate]
          end

      ContributionsByOrigin[election_name] ||= {}
      ContributionsByOrigin[election_name][:race_totals] ||= []
      ContributionsByOrigin[election_name][:race_totals].append({
        title: office_election.title,
        type: 'office',
        slug: slugify(office_election.title),
        amount: candidates.sum {|candidate| candidate.calculation(:total_contributions) || 0.0}
      })

      f.puts(YAML.dump({
        'election' => election_path[1..-1],
        'candidates' => candidates.map { |candidate| slugify(candidate.Candidate) },
        'title' => office_election.title,
        'label' => office_election.label,
      }.compact))
      f.puts('---')
    end
  end
end

# /_committees/1386416.md
Committee.find_each do |committee|
  build_file("/_committees/#{committee.Filer_ID}.md") do |f|
    f.puts(YAML.dump(
      'filer_id' => committee.Filer_ID.to_s,
      'name' => committee.Filer_NamL,
      'candidate_controlled_id' => committee.candidate_controlled_id.to_s,
      'data_warning' => committee.data_warning,
      'opposing_candidate' => committee.opposing_candidate,
      'title' => committee.Filer_NamL,
    ))
    f.puts('---')
  end
end
Candidate.find_each do |committee|
  build_file("/_committees/#{committee.FPPC}.md") do |f|
    f.puts(YAML.dump(
      'filer_id' => committee.FPPC.to_s,
      'name' => committee.Committee_Name,
      'candidate_controlled_id' => '',
      'title' => committee.Committee_Name,
      'data_warning' => committee.data_warning,
    ))
    f.puts('---')
  end
end

# /_data/contributions/1229791.json
Committee.includes(:calculations).find_each do |committee|
  next if committee['Filer_ID'].nil?
  next if committee['Filer_ID'] =~ /pending/i

  build_file("/_data/committees/#{committee['Filer_ID']}.json") do |f|
    f.puts JSON.pretty_generate(
      total_contributions: committee.calculation(:total_contributions),
      contributions: committee.calculation(:contribution_list) || [],
    )
  end
end

Referendum.includes(:calculations).find_each do |referendum|
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
  build_file("/_referendums/#{locality}/#{election.date}/#{title}.md") do |f|
    f.puts(YAML.dump(
      'election' => election.date.to_s,
      'locality' => locality,
      'number' => referendum['Measure_number'] =~ /PENDING/ ? nil : referendum['Measure_number'],
      'title' => referendum['Short_Title'],
      'data_warning' => referendum['data_warning'],
    ))
    f.puts('---')
    f.puts(referendum['Summary'])
  end

  # /_data/referendum_supporting/oakland/2018-11-06/oakland-childrens-initiative.json
  build_file("/_data/referendum_supporting/#{locality}/#{election.date}/#{title}.json") do |f|
    f.puts JSON.pretty_generate(referendum.as_json.merge(
      contributions_by_region: referendum.calculation(:supporting_locales) || [],
      contributions_by_type: referendum.calculation(:supporting_type) || [],
      supporting_organizations: referendum.calculation(:supporting_organizations) || [],
      total_contributions: referendum.calculation(:supporting_total) || [],
    ))
  end

  # /_data/referendum_opposing/oakland/2018-11-06/oakland-childrens-initiative.json
  build_file("/_data/referendum_opposing/#{locality}/#{election.date}/#{title}.json") do |f|
    f.puts JSON.pretty_generate(referendum.as_json.merge(
      contributions_by_region: referendum.calculation(:opposing_locales) || [],
      contributions_by_type: referendum.calculation(:opposing_type) || [],
      opposing_organizations: referendum.calculation(:opposing_organizations) || [],
      total_contributions: referendum.calculation(:opposing_total) || [],
    ))
  end

  supporting_total = referendum.calculation(:supporting_total) || 0
  opposing_total = referendum.calculation(:opposing_total) || 0
  ContributionsByOrigin[referendum.election_name] ||= {}
  ContributionsByOrigin[referendum.election_name][:race_totals] ||= []
  ContributionsByOrigin[referendum.election_name][:race_totals].append({
    title: "Measure #{referendum['Measure_number']}",
    type: 'referendum',
    slug: title,
    amount: supporting_total + opposing_total
  })
end

build_file('/_data/totals.json') do |f|
  f.puts JSON.pretty_generate(
    Hash[ELECTIONS.map do |election_name, election|
      totals = ContributionsByOrigin.fetch(election_name, {})
      totals[:largest_independent_expenditures] = election.calculation(:largest_independent_expenditures)

      # Grab top 3 most expensive races
      totals[:most_expensive_races] = totals[:race_totals].sort_by {|v| -v[:amount]}[0..2]
      totals.delete(:race_totals)

      # Get the top 3 small contribution proprtions
      unless totals[:small_proportion].nil?
        totals[:largest_small_proportion] = totals[:small_proportion].sort_by {|v| -v[:proportion]}[0..2]
      end
      totals.delete(:small_proportion)

      [election_name, totals]
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
