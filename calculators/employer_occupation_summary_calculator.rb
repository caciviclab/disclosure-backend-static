# Summarizes itemized contributions from individuals by the contributor's
# employer and occupation. Since Tran_Emp/Tran_Occ are freeform, different
# spellings of the same value are coalesced via ContributorNameCoalescer. The
# display name for each group is the most common raw spelling within it.
class EmployerOccupationSummaryCalculator
  # Number of employer/occupation groups to keep per filer; the remainder is
  # rolled up into an "Other" entry.
  TOP_N = 25

  def initialize(candidates: [], ballot_measures: [], committees: [])
    @committees = committees
    @candidates = candidates
  end

  def fetch
    results = ActiveRecord::Base.connection.execute(<<-SQL)
      WITH all_committees AS (
        SELECT DISTINCT "Filer_ID", "Start_Date", "End_Date"
        FROM committees
        WHERE NOT EXISTS (SELECT * FROM candidates
                          WHERE "FPPC"::varchar = "Filer_ID")
        UNION
        SELECT DISTINCT "FPPC"::varchar AS "Filer_ID", "Start_Date", "End_Date"
        FROM candidates
      )
      SELECT all_contributions."Filer_ID", "Tran_Emp", "Tran_Occ",
        COUNT(*) AS count, SUM("Tran_Amt1") AS total
      FROM all_contributions
      JOIN all_committees
      ON all_committees."Filer_ID" = all_contributions."Filer_ID"
      AND ("Start_Date" IS NULL OR "Tran_Date" >= "Start_Date")
      AND ("End_Date" IS NULL OR "Tran_Date" <= "End_Date")
      WHERE "Entity_Cd" = 'IND'
      GROUP BY all_contributions."Filer_ID", "Tran_Emp", "Tran_Occ"
    SQL

    employers_by_filer = Hash.new { |h, k| h[k] = {} }
    occupations_by_filer = Hash.new { |h, k| h[k] = {} }

    results.each do |row|
      filer_id = row['Filer_ID'].to_s
      count = row['count'].to_i
      total = row['total'].to_f

      add_to_group(employers_by_filer[filer_id],
                   ContributorNameCoalescer.employer_key(row['Tran_Emp'], row['Tran_Occ']),
                   row['Tran_Emp'], total, count)
      add_to_group(occupations_by_filer[filer_id],
                   ContributorNameCoalescer.occupation_key(row['Tran_Occ']),
                   row['Tran_Occ'], total, count)
    end

    [
      [@committees, 'Filer_ID'],
      [@candidates, 'FPPC']
    ].each do |collection, id|
      collection.each do |committee_or_candidate|
        filer_id = committee_or_candidate[id].to_s
        committee_or_candidate.save_calculation(
          :contributions_by_employer,
          summarize(employers_by_filer[filer_id])
        )
        committee_or_candidate.save_calculation(
          :contributions_by_occupation,
          summarize(occupations_by_filer[filer_id])
        )
      end
    end
  end

  private

  def add_to_group(groups, key, raw_value, total, count)
    group = groups[key] ||= { total: 0.0, count: 0, variants: Hash.new(0) }
    group[:total] += total
    group[:count] += count
    group[:variants][raw_value.to_s.strip] += count
  end

  def summarize(groups)
    sorted = groups.map do |key, group|
      {
        'name' => display_name(key, group[:variants]),
        'total' => group[:total].round(2),
        'count' => group[:count],
      }
    end.sort_by { |entry| [-entry['total'], entry['name']] }

    summary = sorted.first(TOP_N)
    rest = sorted.drop(TOP_N)
    if rest.any?
      summary << {
        'name' => 'Other',
        'total' => rest.sum { |entry| entry['total'] }.round(2),
        'count' => rest.sum { |entry| entry['count'] },
      }
    end
    summary
  end

  # Use the most common raw spelling as the group's display name, except for
  # keys with a fixed display name (synthetic buckets like "Unknown", and
  # occupation-derived groups like Oakland Fire Department whose most common
  # raw employer spelling is "City of Oakland").
  def display_name(key, variants)
    ContributorNameCoalescer::FIXED_DISPLAY_NAMES[key] ||
      variants.max_by { |value, count| [count, value] }.first
  end
end
