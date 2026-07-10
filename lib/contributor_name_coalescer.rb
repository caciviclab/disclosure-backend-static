# Coalesces freeform Tran_Emp / Tran_Occ values so that different spellings of
# the same employer or occupation are grouped together. Values are reduced to a
# normalized "key" (uppercased, punctuation stripped, corporate suffixes
# removed, known aliases applied). Everything that shares a key is treated as
# the same employer/occupation.
module ContributorNameCoalescer
  # Synthetic buckets. These are keys that don't correspond to a real
  # employer/occupation name, so they get a fixed display name.
  UNKNOWN = 'Unknown'.freeze
  # Retired and not-employed are one bucket: contributors use the two labels
  # interchangeably, so the split was more noise than signal.
  RETIRED_NOT_EMPLOYED = 'Retired/Not Employed'.freeze
  SELF_EMPLOYED = 'Self-Employed'.freeze
  HOMEMAKER = 'Homemaker'.freeze

  # A blank employer usually means the contributor has none (retired, not
  # employed, homemaker) — those inherit their status from the occupation
  # field. When the occupation is a real job but the employer is blank, the
  # contributor chose not to report it, which is worth showing on its own.
  # UNKNOWN is reserved for rows where both fields are blank.
  EMPLOYER_NOT_REPORTED = 'Employer not reported'.freeze
  OCCUPATION_NOT_REPORTED = 'Occupation not reported'.freeze

  # Oakland's police and fire departments are kept separate from the general
  # City of Oakland employer group because they are the city's two biggest
  # departments and their unions are politically active. Most of their members
  # list "City of Oakland" as employer, so contributions are assigned to these
  # groups based on the contributor's occupation (see employer_key).
  OAKLAND_FIRE = 'OAKLAND FIRE DEPARTMENT'.freeze
  OAKLAND_POLICE = 'OAKLAND POLICE DEPARTMENT'.freeze

  # The District Attorney's office is likewise kept separate from the general
  # Alameda County employer group. Staff who list just "Alameda County" as
  # employer are assigned by their occupation, as with police/fire above.
  ALAMEDA_DA = 'ALAMEDA COUNTY DISTRICT ATTORNEY'.freeze

  FIRE_OCCUPATIONS = /\b(FIREFIGHTER|FIRE|FIREMAN|BATTALION)\b/
  POLICE_OCCUPATIONS = /\b(POLICE|SERGEANT|DETECTIVE)\b/
  DA_OCCUPATIONS = /\b(DISTRICT ATTORNEY|DA)\b/

  # Keys whose display name is fixed rather than derived from the most common
  # raw spelling in the group (which for the police/fire groups would usually
  # be "City of Oakland").
  FIXED_DISPLAY_NAMES = {
    UNKNOWN => UNKNOWN,
    RETIRED_NOT_EMPLOYED => RETIRED_NOT_EMPLOYED,
    SELF_EMPLOYED => SELF_EMPLOYED,
    HOMEMAKER => HOMEMAKER,
    EMPLOYER_NOT_REPORTED => EMPLOYER_NOT_REPORTED,
    OCCUPATION_NOT_REPORTED => OCCUPATION_NOT_REPORTED,
    OAKLAND_FIRE => 'Oakland Fire Department',
    OAKLAND_POLICE => 'Oakland Police Department',
    ALAMEDA_DA => "Alameda County District Attorney's Office",
    # CEO and President are usually the same top-of-company role, reported
    # under whichever title the contributor prefers.
    'CEO' => 'Chief Executive Officer/President',
    # Umbrella group for brokers, developers, investors, etc. Without a fixed
    # name it displays as whichever specialty is most common among a filer's
    # donors (e.g. "Real Estate Broker"), misrepresenting the group.
    'REAL ESTATE' => 'Real Estate',
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

  # A trailing "CA" is usually a location tag ("City of Berkeley, CA") and is
  # stripped like a corporate suffix -- except after these words, where it is
  # part of the organization's name ("State of CA", "ACLU of Northern CA").
  CA_NAME_PRECEDERS = %w[OF NORTHERN SOUTHERN].freeze

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
    'OAKLAND UNIFIED SCHOOL DISTRIT' => 'OAKLAND UNIFIED SCHOOL DISTRICT',
    # School district acronyms. "<City> USD" spellings are expanded by a
    # generic rule in base_employer_key; the acronyms need a map. Ambiguous
    # ones (SLUSD: San Leandro or San Lorenzo; PUSD) are left alone.
    'SFUSD' => 'SAN FRANCISCO UNIFIED SCHOOL DISTRICT',
    'SF UNIFIED SCHOOL DISTRICT' => 'SAN FRANCISCO UNIFIED SCHOOL DISTRICT',
    'LAUSD' => 'LOS ANGELES UNIFIED SCHOOL DISTRICT',
    'BUSD' => 'BERKELEY UNIFIED SCHOOL DISTRICT',
    'HUSD' => 'HAYWARD UNIFIED SCHOOL DISTRICT',
    'WCCUSD' => 'WEST CONTRA COSTA UNIFIED SCHOOL DISTRICT',
    'CVUSD' => 'CASTRO VALLEY UNIFIED SCHOOL DISTRICT',
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
    # "of CA" endings are protected from the trailing-CA strip, so spell out
    # the ones that have a full-name twin group.
    'STATE OF CA' => 'STATE OF CALIFORNIA',
    'UNIVERSITY OF CA' => 'UNIVERSITY OF CALIFORNIA',
    'ACLU OF NORTHERN CA' => 'ACLU OF NORTHERN CALIFORNIA',
    # The Permanente Medical Group is Kaiser's physician group; contributors
    # report the same jobs under both names.
    'PERMANENTE MEDICAL GROUP' => 'KAISER PERMANENTE',
    'PERMANENTE FEDERATION' => 'KAISER PERMANENTE',
    'TPMG' => 'KAISER PERMANENTE',
    'NEW SCHOOLS VENTURE FUND' => 'NEWSCHOOLS VENTURE FUND',
    'PETFOOD EXPRESS' => 'PET FOOD EXPRESS',
    'CALIFORNIA TEACHER S ASSOCIATION' => 'CALIFORNIA TEACHERS ASSOCIATION',
    'FARMER S INSURANCE' => 'FARMERS INSURANCE',
    'WELLS FARGO BANK' => 'WELLS FARGO',
    'SALESFORCE COM' => 'SALESFORCE',
    'STANFORD' => 'STANFORD UNIVERSITY',
    'EDUCATION FOR CHANGE PUBLIC SCHOOLS' => 'EDUCATION FOR CHANGE',
    'LA CLINICA' => 'LA CLINICA DE LA RAZA',
    'WENDEL ROSEN BLACK & DEAN' => 'WENDEL ROSEN',
    'GREAT OAKLAND PUBLIC SCHOOLS' => 'GREAT OAKLAND PUBLIC SCHOOLS LEADERSHIP CENTER',
    'GO PUBLIC SCHOOLS OAKLAND' => 'GO PUBLIC SCHOOLS',
    'COLDWELL BANKER REAL ESTATE' => 'COLDWELL BANKER',
    'SCI CONSULTING' => 'SCI CONSULTING GROUP',
    # DA's-office spellings that the ALAMEDA COUNTY DISTRICT ATTORNEY prefix
    # merge can't catch. The bare "DA Office" / "District Attorney's Office"
    # spellings are assumed to mean Alameda County's; spellings naming another
    # county (San Francisco, Yolo, ...) keep their own groups.
    'ALAMEDA COUNTY DA' => ALAMEDA_DA,
    'DA OFFICE' => ALAMEDA_DA,
    'DISTRICT ATTORNEY S OFFICE' => ALAMEDA_DA,
    'OFFICE OF THE DISTRICT ATTORNEY OF ALAMEDA' => ALAMEDA_DA,
    'ALAMEDA COUNTY PUBLIC HEALTH DEPARTMENT' => 'ALAMEDA COUNTY',
    'ALAMEDA COUNTY BOARD OF SUPERVISORS' => 'ALAMEDA COUNTY',
    'ALAMEDA COUNTY SOCIAL SERVICES AGENCY' => 'ALAMEDA COUNTY',
    'OAKLAND PUBLOC EDUCATION FUND' => 'OAKLAND PUBLIC EDUCATION FUND',
    'UC BERKELEY GOLDMAN SCHOOL OF PUBLIC POLICY' => 'UC BERKELEY',
    'OAKLAND UNIFED SCHOOL DISTRICT' => 'OAKLAND UNIFIED SCHOOL DISTRICT',
    'MORRISON FOERSTER' => 'MORRISON & FOERSTER',
    'CITY OF BERKELEY CA' => 'CITY OF BERKELEY',
    'GOOGLE VENTURES' => 'GOOGLE',
    'SAN FRANCISCO UNIFED SCHOOL DISTRICT' => 'SAN FRANCISCO UNIFIED SCHOOL DISTRICT',
    'CALIFORNIA NURSES' => 'CALIFORNIA NURSES ASSOCIATION',
    'ALAMEDA COUNTY COMPLETE COUNT COMMITTEE FOR CENSUS 2020' => 'ALAMEDA COUNTY',
    'CLAREMONT REALTOR' => 'CLAREMONT REALTY',
    'EDUCATE 78' => 'EDUCATE78',
    'TORRES LAW GROUP 1211 EMBARCADERO STE 210 OAKLAND CA 94606' => 'TORRES LAW GROUP',
    'OAKLAND UNIFIED SCHOOL DISTICT' => 'OAKLAND UNIFIED SCHOOL DISTRICT',
    'CITY OF OAKLAMD' => 'CITY OF OAKLAND',
    'TORRES LAW' => 'TORRES LAW GROUP',
    'MEYERS NAVE RIBACK SILVER & WILSON' => 'MEYERS NAVE',
    'ROCKWOOD LEADERSHIP INSTITUE' => 'ROCKWOOD LEADERSHIP INSTITUTE',
    'SIEGEL YEE' => 'SIEGEL & YEE',
    'ASPIRE' => 'ASPIRE PUBLIC SCHOOLS',
    'ROCKWOOD' => 'ROCKWOOD LEADERSHIP INSTITUTE',
    'META PLATFORMS' => 'META',
    'RIAZ' => 'RIAZ CAPITAL',
    'ALAMEDA HEALTH SYSTEMS' => 'ALAMEDA HEALTH SYSTEM',
    'BURKE WILLIAMS & SORENSON' => 'BURKE WILLIAMS & SORENSEN',
    'GENETECH' => 'GENENTECH',
    'OAKLAND RISING ACTION' => 'OAKLAND RISING',
    'SENECA' => 'SENECA FAMILY OF AGENCIES',
    'PERALTA' => 'PERALTA COMMUNITY COLLEGE DISTRICT',
    'MORGAN LEWIS & BOCKIUS' => 'MORGAN LEWIS',
    'UNIVERSITY OF CALIFORNIA OFFICE OF THE PRESIDENT' => 'UNIVERSITY OF CALIFORNIA',
    'PERALTA COMMUNITY COLLEGE' => 'PERALTA COMMUNITY COLLEGE DISTRICT',
    'LODESTAR K 5' => 'LODESTAR',
    'MILO GROUP' => 'MILO GROUP OF CALIFORNIA',
    'POLICY LINK' => 'POLICYLINK',
    'LIFELONG MEDICAL' => 'LIFELONG MEDICAL CARE',
    'KOS READ GROUP COMMUNICATIONS & PUBLIC AFFAIRS' => 'KOS READ GROUP',
    'MILLS COLLEGE AT NORTHEASTERN' => 'MILLS COLLEGE',
    'SALEFORCE' => 'SALESFORCE',
    'LIGHTHOUSE' => 'LIGHTHOUSE COMMUNITY CHARTER PUBLIC SCHOOLS',
    'DELOITTE CONSULTING' => 'DELOITTE',
    'GREAT OAKLAND PUBLIC SCHOOL LEADERSHIP CENTER' => 'GREAT OAKLAND PUBLIC SCHOOLS LEADERSHIP CENTER',
    'BART BAY AREA RAPID TRANSIT' => 'BART',
    'MCCONNEL GROUP' => 'MCCONNELL GROUP',
    'NATIONAL UNION OF HEALTHCARE WORKERS NUHW' => 'NATIONAL UNION OF HEALTHCARE WORKERS',
    'AKONADI' => 'AKONADI FOUNDATION',
    'FUSD' => 'FREMONT UNIFIED SCHOOL DISTRICT',
    'SUTTER' => 'SUTTER HEALTH',
    'SAN FRANCISCO STATE' => 'SAN FRANCISCO STATE UNIVERSITY',
    'COLDWELL BANKER REALTY' => 'COLDWELL BANKER',
    'UC BERKELEY CENTER FOR LABOR RESEARCH' => 'UC BERKELEY',
    'TIDES CENTER PODER' => 'TIDES CENTER',
    'STATE OF CALIFORNIA CAL OSHA' => 'STATE OF CALIFORNIA',
    'FARMERS INSURANCE RUTH STRUOP AGENCY' => 'FARMERS INSURANCE',
    'GREAT SCHOOL CHOICES' => 'GREAT SCHOOL VOICES',
    'ALAMEDA COUNTY IHSS' => 'ALAMEDA COUNTY',
    'COMPASS LEXECON' => 'COMPASS',
    'EPA' => 'US EPA',
    'EDUCATION' => 'EDUCATION FOR CHANGE',
    'PLANNED PARENTHOOD' => 'PLANNED PARENTHOOD MAR MONTE',
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
    # Catches "... District Attorney", "... District Attorneys Office",
    # "... District Attorney's Office", with or without "County".
    'ALAMEDA COUNTY DISTRICT ATTORNEY' => ALAMEDA_DA,
    'ALAMEDA DISTRICT ATTORNEY' => ALAMEDA_DA,
  }.freeze

  OCCUPATION_ALIASES = {
    'ACCOUNTING' => 'ACCOUNTANT',
    'ADMINISTRATION' => 'ADMINISTRATOR',
    'ATTORNEY AT LAW' => 'ATTORNEY',
    'ATTY' => 'ATTORNEY',
    'BUSINESS DEVELOPMENT' => 'BUSINESS DEVELOPMENT MANAGER',
    'BUSINESS' => 'OWNER',
    'C E O' => 'CEO',
    'CEO PRESIDENT' => 'CEO',
    # Founders serving as CEO belong in the CEO group; the founder half of
    # the title doesn't change the role.
    'FOUNDER CEO' => 'CEO',
    'FOUNDER & CEO' => 'CEO',
    'FOUNDER AND CEO' => 'CEO',
    'CEO FOUNDER' => 'CEO',
    'CEO & FOUNDER' => 'CEO',
    'CEO AND FOUNDER' => 'CEO',
    'FOUNDER CHIEF EXECUTIVE OFFICER' => 'CEO',
    'FOUNDER & CHIEF EXECUTIVE OFFICER' => 'CEO',
    'FOUNDER AND CHIEF EXECUTIVE OFFICER' => 'CEO',
    'CHIEF EXECUTIVE OFFICER FOUNDER' => 'CEO',
    'CO FOUNDER CEO' => 'CEO',
    'CO FOUNDER & CEO' => 'CEO',
    'CO FOUNDER AND CEO' => 'CEO',
    'CO FOUNDER CO CEO' => 'CEO',
    'CO FOUNDER & CHIEF EXECUTIVE OFFICER' => 'CEO',
    'CO FOUNDER AND CHIEF EXECUTIVE OFFICER' => 'CEO',
    'CO FOUNDER CHIEF EXECUTIVE OFFICER' => 'CEO',
    'CEO CO FOUNDER' => 'CEO',
    'CEO AND CO FOUNDER' => 'CEO',
    'CHIEF EXECUTIVE OFFICER CO FOUNDER' => 'CEO',
    'STARTUP FOUNDER AND CEO' => 'CEO',
    'CHIEF EXECUTIVE OFFICER' => 'CEO',
    'CHIEF FINANCIAL OFFICER' => 'CFO',
    'CHIEF OPERATING OFFICER' => 'COO',
    'CITY COUNCIL MEMBER' => 'CITY COUNCILMEMBER',
    'COMMUNICATIONS STRATEGIST' => 'COMMUNICATIONS',
    'CONSULTING' => 'CONSULTANT',
    'COUNCIL MEMBER' => 'CITY COUNCILMEMBER',
    'DOCTOR' => 'PHYSICIAN',
    'EDUCATIONAL CONSULTANT' => 'EDUCATION CONSULTANT',
    'FINANCE MANAGER' => 'FINANCE',
    'FIRE FIGHTER' => 'FIREFIGHTER',
    'GRAPHIC DESIGN' => 'GRAPHIC DESIGNER',
    'HOUSE WIFE' => 'HOMEMAKER',
    'HOUSEWIFE' => 'HOMEMAKER',
    'LAWYER' => 'ATTORNEY',
    'MANAGER OF EDUCATOR COMMUNITY' => 'MANAGER',
    'MARKETING MANAGER' => 'MARKETING',
    'MD' => 'PHYSICIAN',
    'NONPROFIT DIRECTOR' => 'NON PROFIT DIRECTOR',
    'NONPROFIT EXECUTIVE' => 'NON PROFIT EXECUTIVE',
    'NURSE MIDWIFE' => 'NURSE',
    'NURSE PRACTITIONER' => 'NURSE',
    'OPERATIONS' => 'OPERATIONS MANAGER',
    'PRESIDENT & CEO' => 'CEO',
    'PRESIDENT &AMP CEO' => 'CEO',
    'PRESIDENT AND CEO' => 'CEO',
    'PRESIDENT CEO' => 'CEO',
    'PRESIDENT' => 'CEO',
    'PROGRAMS MANAGER' => 'PROGRAM MANAGER',
    'PUBLIC AFFAIRS' => 'PUBLIC AFFAIRS CONSULTANT',
    'REAL ESTATE AGENT' => 'REAL ESTATE',
    'REAL ESTATE BROKER' => 'REAL ESTATE',
    'REAL ESTATE CONSULTANT' => 'REAL ESTATE',
    'REAL ESTATE DEVELOPER' => 'REAL ESTATE',
    'REAL ESTATE DEVELOPMENT' => 'REAL ESTATE',
    'REAL ESTATE INVESTMENT' => 'REAL ESTATE',
    'REAL ESTATE INVESTOR' => 'REAL ESTATE',
    'REAL ESTATE MANAGER' => 'REAL ESTATE',
    'REAL ESTATE OWNER MANAGER' => 'REAL ESTATE',
    'REAL ESTATE PROFESSIONAL' => 'REAL ESTATE',
    'REALTOR' => 'REAL ESTATE',
    'RN' => 'REGISTERED NURSE',
    'SALES DIRECTOR' => 'SALES',
    'SALES MANAGER' => 'SALES',
    'SENIOR DIRECTOR OF INNOVATION AND LEARNING' => 'SENIOR DIRECTOR',
    'SOFTWARE DEVELOPER' => 'SOFTWARE ENGINEER',
    'STAY AT HOME MOM' => 'HOMEMAKER',
    'TEACHER LEADER' => 'TEACHER',
    'CREATIVE DIRECTION' => 'CREATIVE DIRECTOR',
    'MANAGER DIPR' => 'MANAGER',
    'MARKETING DIRECTOR' => 'MARKETING',
    'EDUCATION ASSOCIATE' => 'EDUCATION',
    'SALES ASSOCIATE' => 'SALES',
    'REAL ESTATE PROPERTY OWNER' => 'PROPERTY OWNER',
    'RESEARCH' => 'RESEARCHER',
    # Generic and business-type owners merge into the Owner group. Property/
    # rental owners (landlords) are deliberately kept separate -- that's a
    # politically meaningful category in Oakland races -- and real-estate
    # owner spellings route to the REAL ESTATE group above.
    'BUSINESS OWNER' => 'OWNER',
    'SMALL BUSINESS OWNER' => 'OWNER',
    'CO OWNER' => 'OWNER',
    'OWNERS' => 'OWNER',
    'OWNER MANAGER' => 'OWNER',
    'OWNER OPERATOR' => 'OWNER',
    'OWNER OPERAATOR' => 'OWNER',
    'RESTAURANT OWNER' => 'OWNER',
    'OWNER RESTAURATEUR' => 'OWNER',
    'CAFE OWNER' => 'OWNER',
    'BAR OWNER' => 'OWNER',
    'BOUTIQUE OWNER' => 'OWNER',
    'STORE OWNER' => 'OWNER',
    'HOTEL OWNER' => 'OWNER',
    'GALLERY OWNER' => 'OWNER',
    'AGENCY OWNER' => 'OWNER',
    # "Principal" here is the head-of-firm sense (consulting, construction),
    # not a school principal; GM/Owner is an owner who also manages.
    'OWNER PRINCIPAL' => 'OWNER',
    'PRINCIPAL OWNER' => 'OWNER',
    'GM OWNER' => 'OWNER',
    # Executive Director (nonprofit chief) variants, including founders
    # serving as ED. Qualified titles ("Assistant ...", "Executive Managing
    # Director") are different roles and stay separate.
    'EXEC DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'EXEC DIR' => 'EXECUTIVE DIRECTOR',
    'ED' => 'EXECUTIVE DIRECTOR',
    'E D' => 'EXECUTIVE DIRECTOR',
    'EXECUTIVE DIRECTOR OAKLAND' => 'EXECUTIVE DIRECTOR',
    'EXECUTIVE DIRECTOR OF PROFESSIONAL LEARNING' => 'EXECUTIVE DIRECTOR',
    'EXECUTIVE DIRECTOR NONPROFIT ORGANIZATION' => 'EXECUTIVE DIRECTOR',
    'NONPROFIT EXECUTIVE DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'NON PROFIT EXECUTIVE DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'NONPROFIT EXEC DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'INTERIM EXECUTIVE DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'CO EXECUTIVE DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'PRESIDENT AND EXECUTIVE DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'PRESIDENT & EXECUTIVE DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'EXECUTIVE DIRECTOT' => 'EXECUTIVE DIRECTOR',
    'EXEXCUTIVE DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'FOUNDER AND EXECUTIVE DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'FOUNDER & EXECUTIVE DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'FOUNDER EXECUTIVE DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'CO FOUNDER AND EXECUTIVE DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'CO FOUNDER & EXECUTIVE DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'CO FOUNDER EXECUTIVE DIRECTOR' => 'EXECUTIVE DIRECTOR',
    'REAL ESTATE APPRAISER' => 'REAL ESTATE',
    'ASSOCIATE DIRECTOR OF MEDIA RELATIONS' => 'ASSOCIATE DIRECTOR',
    'EDUCATION POLICY' => 'EDUCATION',
    'ATTORNEY CONSULTANT' => 'ATTORNEY',
  }.freeze

  # Uppercase, replace punctuation with spaces, and collapse whitespace so
  # "Self-Employed", "SELF EMPLOYED." and "self  employed" all produce the
  # same key.
  def self.normalize(raw)
    raw.to_s.upcase.gsub(/[^A-Z0-9& ]/, ' ').squeeze(' ').strip
  end

  def self.employer_key(raw, occupation = nil)
    key = base_employer_key(raw)

    # Police and fire employees usually list just "City of Oakland" as their
    # employer; use the occupation to assign them to their department.
    if key == 'CITY OF OAKLAND' && occupation
      occ = normalize(occupation)
      return OAKLAND_FIRE if FIRE_OCCUPATIONS.match?(occ)
      return OAKLAND_POLICE if POLICE_OCCUPATIONS.match?(occ)
    end

    # Likewise, DA staff often list just "Alameda County" as their employer.
    if key == 'ALAMEDA COUNTY' && occupation &&
       DA_OCCUPATIONS.match?(normalize(occupation))
      return ALAMEDA_DA
    end

    # A blank employer mostly means there is none; let the occupation say so.
    if key == UNKNOWN
      occ_key = base_occupation_key(occupation)
      return UNKNOWN if occ_key == UNKNOWN
      return RETIRED_NOT_EMPLOYED if occ_key == RETIRED_NOT_EMPLOYED ||
                                     occ_key.start_with?('RETIRED')
      return SELF_EMPLOYED if occ_key == SELF_EMPLOYED
      return HOMEMAKER if occ_key == 'HOMEMAKER'

      return EMPLOYER_NOT_REPORTED
    end

    key
  end

  def self.occupation_key(raw, employer = nil)
    key = base_occupation_key(raw)
    return key unless key == UNKNOWN

    # A blank occupation can still inherit no-employment status from the
    # employer field ("Retired", "Not Employed", ... are common there too).
    emp_key = base_employer_key(employer)
    return UNKNOWN if emp_key == UNKNOWN
    return emp_key if [RETIRED_NOT_EMPLOYED, SELF_EMPLOYED].include?(emp_key)
    return HOMEMAKER if emp_key == 'HOMEMAKER'

    OCCUPATION_NOT_REPORTED
  end

  def self.base_employer_key(raw)
    key = normalize(raw)
    return UNKNOWN if UNKNOWN_KEYS.include?(key)
    return RETIRED_NOT_EMPLOYED if NOT_EMPLOYED_KEYS.include?(key) ||
                                   key.start_with?('RETIRED')
    return SELF_EMPLOYED if SELF_EMPLOYED_KEYS.include?(key) ||
                            key.start_with?('SELF EMPLOYED')

    key = strip_suffixes(key)
    key = key.sub(/\ATHE /, '')
    # "<City> USD" is the standard abbreviation of "<City> Unified School
    # District"; expand it so both spellings share a group.
    key = key.sub(/\A(.+) USD\z/, '\1 UNIFIED SCHOOL DISTRICT')
    EMPLOYER_ALIASES[key] || apply_prefix_merges(key)
  end

  def self.base_occupation_key(raw)
    key = normalize(raw)
    return UNKNOWN if UNKNOWN_KEYS.include?(key)
    return RETIRED_NOT_EMPLOYED if NOT_EMPLOYED_KEYS.include?(key) ||
                                   key == 'RETIRED'
    return SELF_EMPLOYED if key == 'SELF' || key.start_with?('SELF EMPLOYED')

    OCCUPATION_ALIASES.fetch(key, key)
  end

  def self.apply_prefix_merges(key)
    EMPLOYER_PREFIX_MERGES.each do |prefix, target|
      return target if key.start_with?(prefix)
    end
    key
  end

  def self.strip_suffixes(key)
    words = key.split(' ')
    while words.length > 1
      if CORPORATE_SUFFIXES.include?(words.last) ||
         (words.last == 'CA' && !CA_NAME_PRECEDERS.include?(words[-2]))
        words.pop
      else
        break
      end
    end
    words.join(' ')
  end
end
