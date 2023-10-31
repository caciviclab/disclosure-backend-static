class ElectionTotal
  def initialize(candidates: [], ballot_measures: [], committees: []); end

  def self.dependencies
    [
      { model: Candidate, calculation: :total_contributions },
      { model: Candidate, calculation: :total_small_contributions },
      { model: Candidate, calculation: :contributions_by_origin },
      { model: Referendum, calculation: :supporting_total },
      { model: Referendum, calculation: :opposing_total },
      { model: Referendum, calculation: :supporting_type },
      { model: Referendum, calculation: :opposing_type },
    ]
  end

  def fetch
    Election.find_each do |election|

      election_total = 0
      race_totals = []
      small_proportion = []
      by_origin = {}
      by_type = {}
      OfficeElection.where(election_name: election['name']).find_each do |office_election|
        total_contributions = 0
        Candidate
          .where(Office: office_election.title, election_name: election['name'])
          .includes(:office_election, :calculations)
          .find_each do |candidate|

          total = candidate.calculation(:total_contributions) ||
            candidate.calculation(:contribution_list_total)
          total_contributions += total
          total_small = candidate.calculation(:total_small_contributions)

          unless total == 0 || total_small.nil?
            small_proportion.append({
              title: election['title'],
              type: 'office',
              office_title: candidate.office_election.title,
              slug: slugify(candidate['Candidate']),
              candidate: candidate['Candidate'],
              proportion: candidate.calculation(:total_small_contributions) / total.to_f
            })
          end

          # Sum contribution by orgin information for whole election
          contributions_by_origin = candidate.calculation(:contributions_by_origin)
          unless contributions_by_origin.nil?
            by_origin = by_origin.merge(contributions_by_origin){
              |key, oldval, newval| oldval + newval
            }
          end

          # Sum contribution by type information for whole election
          contributions_by_type = candidate.calculation(:contributions_by_type)
          unless contributions_by_type.nil?
            by_type = by_type.merge(contributions_by_type){
              |key, oldval, newval| oldval + newval
            }
          end

        end
        race_totals.append({
          title: office_election.title,
            type: 'office',
            slug: slugify(office_election.title),
            amount: total_contributions
          })
        election_total += total_contributions
      end

      Referendum
        .where(election_name: election['name'])
        .includes(:calculations)
        .find_each do |referendum|

        supporting_total = referendum.calculation(:supporting_total) || 0
        opposing_total = referendum.calculation(:opposing_total) || 0
        race_totals.append({
          title: "Measure #{referendum['Measure_number']}",
          type: 'referendum',
          slug: slugify(referendum['Short_Title']),
          amount: supporting_total + opposing_total
        })
        election_total += supporting_total + opposing_total

        # Sum contribution by orgin information for whole election
        [:supporting_locales, :opposing_locales].each do |locales|
          locale_array = referendum.calculation(locales)
          unless locale_array.nil?
            locale_array.each { |row|
              by_origin[row['locale']] ||= 0
              by_origin[row['locale']] += row['amount']
            }
          end
        end

        # Sum contribution by type information for whole election
        [:supporting_type, :opposing_type].each do |type|
          type_array = referendum.calculation(type)
          unless type_array.nil?
            type_array.each { |row|
              by_type[row['type']] ||= 0
              by_type[row['type']] += row['amount']
            }
          end
        end
      end

      largest = small_proportion.sort_by {|v| -v[:proportion]}[0..2]
      election.save_calculation(:largest_small_proportion, largest)

      races_with_contributions = race_totals.reject { |race| race[:amount] == 0 }
      largest = races_with_contributions.sort_by { |v| -v[:amount] }[0..2]
      election.save_calculation(:most_expensive_races, largest)

      election.save_calculation(:contributions_by_origin, by_origin)
      election.save_calculation(:contributions_by_type, by_type)
      election.save_calculation(:total_contributions, election_total.round(2))
    end
  end
end
