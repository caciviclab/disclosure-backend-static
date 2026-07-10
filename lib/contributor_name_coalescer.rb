# Coalesces freeform Tran_Emp / Tran_Occ values so that different spellings of
# the same employer or occupation are grouped together. Values are reduced to a
# normalized "key" (uppercased, punctuation stripped, corporate suffixes
# removed, known aliases applied). Everything that shares a key is treated as
# the same employer/occupation.
module ContributorNameCoalescer
  # Synthetic buckets. These are keys that don't correspond to a real
  # employer/occupation name, so they get a fixed display name.
  UNKNOWN = 'Unknown'.freeze
  RETIRED = 'Retired'.freeze
  NOT_EMPLOYED = 'Not Employed'.freeze
  SELF_EMPLOYED = 'Self-Employed'.freeze

  # Oakland's police and fire departments are kept separate from the general
  # City of Oakland employer group because they are the city's two biggest
  # departments and their unions are politically active. Most of their members
  # list "City of Oakland" as employer, so contributions are assigned to these
  # groups based on the contributor's occupation (see employer_key).
  OAKLAND_FIRE = 'OAKLAND FIRE DEPARTMENT'.freeze
  OAKLAND_POLICE = 'OAKLAND POLICE DEPARTMENT'.freeze

  FIRE_OCCUPATIONS = /\b(FIREFIGHTER|FIRE|FIREMAN|BATTALION)\b/
  POLICE_OCCUPATIONS = /\b(POLICE|SERGEANT|DETECTIVE)\b/

  # Keys whose display name is fixed rather than derived from the most common
  # raw spelling in the group (which for the police/fire groups would usually
  # be "City of Oakland").
  FIXED_DISPLAY_NAMES = {
    UNKNOWN => UNKNOWN,
    RETIRED => RETIRED,
    NOT_EMPLOYED => NOT_EMPLOYED,
    SELF_EMPLOYED => SELF_EMPLOYED,
    OAKLAND_FIRE => 'Oakland Fire Department',
    OAKLAND_POLICE => 'Oakland Police Department',
  }.freeze

  # Keys (post-normalization) that mean "no meaningful answer".
  UNKNOWN_KEYS = [
    '', 'N A', 'NA', 'NONE', 'NONE GIVEN', 'UNKNOWN', 'ANONYMOUS',
    'INFORMATION REQUESTED', 'REQUESTED', 'DECLINED TO STATE', 'NOT PROVIDED',
    'NOT AVAILABLE', 'NOT STATED', 'VARIOUS', 'TBD', 'X', 'XX', 'XXX', '0'
  ].freeze

  NOT_EMPLOYED_KEYS = [
    'NOT EMPLOYED', 'UNEMPLOYED', 'NOT CURRENTLY EMPLOYED', 'NONE NOT EMPLOYED',
    'NOT APPLICABLE', 'NOT WORKING'
  ].freeze

  # "No separate business name" is the FPPC's phrasing for a self-employed
  # contributor whose business has no name of its own.
  SELF_EMPLOYED_KEYS = [
    'SELF', 'NO SEPARATE BUSINESS NAME', 'NO SEPERATE BUSINESS NAME'
  ].freeze

  # Trailing corporate suffixes that don't distinguish employers
  # ("Google" vs "Google Inc" vs "Google LLC").
  CORPORATE_SUFFIXES = %w[INC INCORPORATED LLC LLP LP LTD PC PLLC CORP].freeze

  # Curated merges, applied to normalized keys. Values are themselves keys, so
  # aliased entries merge with naturally-occurring ones (e.g. 'LAWYER' rows
  # merge into the 'ATTORNEY' group).
  EMPLOYER_ALIASES = {
    'OAKLAND FIRE DEPT' => OAKLAND_FIRE,
    'OAKLAND FIRE' => OAKLAND_FIRE,
    'CITY OF OAKLAND FIRE DEPARTMENT' => OAKLAND_FIRE,
    'CITY OF OAKLAND OAKLAND FIRE' => OAKLAND_FIRE,
    'OAKLAND POLICE DEPT' => OAKLAND_POLICE,
    'CITY OF OAKLAND POLICE DEPARTMENT' => OAKLAND_POLICE,
    'CITY OF OAKLAND OPD' => OAKLAND_POLICE,
    # Other city departments are grouped with the city itself; the
    # contributor's occupation preserves the finer detail.
    'OAKLAND' => 'CITY OF OAKLAND',
    'OAKLAND CITY ATTORNEY' => 'CITY OF OAKLAND',
    'OAKLAND CITY ATTORNEY S OFFICE' => 'CITY OF OAKLAND',
    'OAKLAND CITY COUNCIL' => 'CITY OF OAKLAND',
    'OAKLAND PUBLIC LIBRARY' => 'CITY OF OAKLAND',
    'OUSD' => 'OAKLAND UNIFIED SCHOOL DISTRICT',
    'OAKLAND UNIFIED SCHOOL DIST' => 'OAKLAND UNIFIED SCHOOL DISTRICT',
    'OAKLAND UNIFIED' => 'OAKLAND UNIFIED SCHOOL DISTRICT',
    'UNIVERSITY OF CALIFORNIA BERKELEY' => 'UC BERKELEY',
    'UNIVERSITY OF CALIFORNIA AT BERKELEY' => 'UC BERKELEY',
    'U C BERKELEY' => 'UC BERKELEY',
    'UCB' => 'UC BERKELEY',
    'CAL BERKELEY' => 'UC BERKELEY',
    'EBMUD' => 'EAST BAY MUNICIPAL UTILITY DISTRICT',
    'ALAMEDA CONTRA COSTA TRANSIT DISTRICT' => 'AC TRANSIT',
    'UCSF' => 'UC SAN FRANCISCO',
    'UNIVERSITY OF CALIFORNIA SAN FRANCISCO' => 'UC SAN FRANCISCO',
    'CITY COUNTY OF SAN FRANCISCO' => 'CITY AND COUNTY OF SAN FRANCISCO',
    'NEW SCHOOLS VENTURE FUND' => 'NEWSCHOOLS VENTURE FUND',
    'PETFOOD EXPRESS' => 'PET FOOD EXPRESS',
    'CALIFORNIA TEACHER S ASSOCIATION' => 'CALIFORNIA TEACHERS ASSOCIATION',
    'FARMER S INSURANCE' => 'FARMERS INSURANCE',
    'WELLS FARGO BANK' => 'WELLS FARGO',
    'SALESFORCE COM' => 'SALESFORCE',
    'STANFORD' => 'STANFORD UNIVERSITY',
  }.freeze

  # Employer keys that start with any of these prefixes are merged into the
  # prefix's group. Catches the long tail of site/department qualifiers
  # ("Kaiser Permanente Oakland Medical Center", "Kaiser Foundation ...").
  EMPLOYER_PREFIX_MERGES = {
    'KAISER' => 'KAISER PERMANENTE',
    # Catches "City of Oakland, CA", "City of Oakland, Office of the City
    # Attorney", etc. (Police/fire spellings are aliased to their own groups
    # before prefixes apply.)
    'CITY OF OAKLAND' => 'CITY OF OAKLAND',
  }.freeze

  OCCUPATION_ALIASES = {
    'LAWYER' => 'ATTORNEY',
    'ATTORNEY AT LAW' => 'ATTORNEY',
    'ATTY' => 'ATTORNEY',
    'CHIEF EXECUTIVE OFFICER' => 'CEO',
    'C E O' => 'CEO',
    'CHIEF FINANCIAL OFFICER' => 'CFO',
    'CHIEF OPERATING OFFICER' => 'COO',
    'FIRE FIGHTER' => 'FIREFIGHTER',
    'RN' => 'REGISTERED NURSE',
    'HOUSEWIFE' => 'HOMEMAKER',
    'HOUSE WIFE' => 'HOMEMAKER',
    'STAY AT HOME MOM' => 'HOMEMAKER',
    'REAL ESTATE AGENT' => 'REALTOR',
    'MD' => 'PHYSICIAN',
    'DOCTOR' => 'PHYSICIAN',
    'SOFTWARE DEVELOPER' => 'SOFTWARE ENGINEER',
    'COUNCIL MEMBER' => 'COUNCILMEMBER',
    'CITY COUNCIL MEMBER' => 'CITY COUNCILMEMBER',
    'NONPROFIT EXECUTIVE' => 'NON PROFIT EXECUTIVE',
    'CONSULTING' => 'CONSULTANT',
  }.freeze

  # Uppercase, replace punctuation with spaces, and collapse whitespace so
  # "Self-Employed", "SELF EMPLOYED." and "self  employed" all produce the
  # same key.
  def self.normalize(raw)
    raw.to_s.upcase.gsub(/[^A-Z0-9& ]/, ' ').squeeze(' ').strip
  end

  def self.employer_key(raw, occupation = nil)
    key = normalize(raw)
    return UNKNOWN if UNKNOWN_KEYS.include?(key)
    return NOT_EMPLOYED if NOT_EMPLOYED_KEYS.include?(key)
    return RETIRED if key.start_with?('RETIRED')
    return SELF_EMPLOYED if SELF_EMPLOYED_KEYS.include?(key) ||
                            key.start_with?('SELF EMPLOYED')

    key = strip_corporate_suffixes(key)
    key = key.sub(/\ATHE /, '')
    key = EMPLOYER_ALIASES[key] || apply_prefix_merges(key)

    # Police and fire employees usually list just "City of Oakland" as their
    # employer; use the occupation to assign them to their department.
    if key == 'CITY OF OAKLAND' && occupation
      occ = normalize(occupation)
      return OAKLAND_FIRE if FIRE_OCCUPATIONS.match?(occ)
      return OAKLAND_POLICE if POLICE_OCCUPATIONS.match?(occ)
    end

    key
  end

  def self.occupation_key(raw)
    key = normalize(raw)
    return UNKNOWN if UNKNOWN_KEYS.include?(key)
    return NOT_EMPLOYED if NOT_EMPLOYED_KEYS.include?(key)
    return RETIRED if key == 'RETIRED'
    return SELF_EMPLOYED if key == 'SELF' || key.start_with?('SELF EMPLOYED')

    OCCUPATION_ALIASES.fetch(key, key)
  end

  def self.apply_prefix_merges(key)
    EMPLOYER_PREFIX_MERGES.each do |prefix, target|
      return target if key.start_with?(prefix)
    end
    key
  end

  def self.strip_corporate_suffixes(key)
    words = key.split(' ')
    words.pop while words.length > 1 && CORPORATE_SUFFIXES.include?(words.last)
    words.join(' ')
  end
end
