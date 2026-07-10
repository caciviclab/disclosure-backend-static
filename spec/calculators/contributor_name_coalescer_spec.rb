# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContributorNameCoalescer do
  describe '.employer_key' do
    it 'coalesces case, whitespace, and punctuation variants' do
      expect(described_class.employer_key('City of Oakland'))
        .to eq(described_class.employer_key('CITY OF OAKLAND'))
      expect(described_class.employer_key('Kaiser  Permanente'))
        .to eq(described_class.employer_key('Kaiser Permanente'))
    end

    it 'strips corporate suffixes' do
      expect(described_class.employer_key('Google Inc.'))
        .to eq(described_class.employer_key('Google LLC'))
      expect(described_class.employer_key('Google, Inc')).to eq('GOOGLE')
    end

    it 'merges Kaiser variants' do
      [
        'Kaiser', 'KAISER PERMANENTE', 'Kaiser Foundation Health Plan, Inc.',
        'Kaiser Permanente Oakland Medical Center', 'Kaiser Permante',
        'The Permanente Medical Group', 'Permanente Medical Group, Inc.',
        'TPMG', 'Kaiser Permanente - TPMG'
      ].each do |variant|
        expect(described_class.employer_key(variant)).to eq('KAISER PERMANENTE')
      end
    end

    it 'applies curated aliases' do
      expect(described_class.employer_key('OUSD'))
        .to eq(described_class.employer_key('Oakland Unified School District'))
      expect(described_class.employer_key('UC Berkeley'))
        .to eq(described_class.employer_key('University of California, Berkeley'))
      expect(described_class.employer_key('New Schools Venture Fund'))
        .to eq(described_class.employer_key('NewSchools Venture Fund'))
      expect(described_class.employer_key('Wells Fargo Bank'))
        .to eq(described_class.employer_key('Wells Fargo'))
      expect(described_class.employer_key('EDUCATION FOR CHANGE PUBLIC SCHOOLS'))
        .to eq(described_class.employer_key('EDUCATION FOR CHANGE'))
      expect(described_class.employer_key('LA CLINICA'))
        .to eq(described_class.employer_key('LA CLINICA DE LA RAZA'))
      expect(described_class.employer_key('WENDEL ROSEN BLACK & DEAN'))
        .to eq(described_class.employer_key('WENDEL ROSEN'))
      expect(described_class.employer_key('GREAT OAKLAND PUBLIC SCHOOLS'))
        .to eq(described_class.employer_key('GREAT OAKLAND PUBLIC SCHOOLS LEADERSHIP CENTER'))
      expect(described_class.employer_key('GO PUBLIC SCHOOLS OAKLAND'))
        .to eq(described_class.employer_key('GO PUBLIC SCHOOLS'))
      expect(described_class.employer_key('COLDWELL BANKER REAL ESTATE'))
        .to eq(described_class.employer_key('COLDWELL BANKER'))
      expect(described_class.employer_key('SCI CONSULTING'))
        .to eq(described_class.employer_key('SCI CONSULTING GROUP'))
      expect(described_class.employer_key('ALAMEDA COUNTY PUBLIC HEALTH DEPARTMENT'))
        .to eq(described_class.employer_key('ALAMEDA COUNTY'))
      expect(described_class.employer_key('ALAMEDA COUNTY BOARD OF SUPERVISORS'))
        .to eq(described_class.employer_key('ALAMEDA COUNTY'))
      expect(described_class.employer_key('ALAMEDA COUNTY SOCIAL SERVICES AGENCY'))
        .to eq(described_class.employer_key('ALAMEDA COUNTY'))
      expect(described_class.employer_key('OAKLAND PUBLOC EDUCATION FUND'))
        .to eq(described_class.employer_key('OAKLAND PUBLIC EDUCATION FUND'))
      expect(described_class.employer_key('UC BERKELEY GOLDMAN SCHOOL OF PUBLIC POLICY'))
        .to eq(described_class.employer_key('UC BERKELEY'))
      expect(described_class.employer_key('OAKLAND UNIFED SCHOOL DISTRICT'))
        .to eq(described_class.employer_key('OAKLAND UNIFIED SCHOOL DISTRICT'))
      expect(described_class.employer_key('MORRISON FOERSTER'))
        .to eq(described_class.employer_key('MORRISON & FOERSTER'))
      expect(described_class.employer_key('CITY OF BERKELEY CA'))
        .to eq(described_class.employer_key('CITY OF BERKELEY'))
      expect(described_class.employer_key('GOOGLE VENTURES'))
        .to eq(described_class.employer_key('GOOGLE'))
      expect(described_class.employer_key('SAN FRANCISCO UNIFED SCHOOL DISTRICT'))
        .to eq(described_class.employer_key('SAN FRANCISCO UNIFIED SCHOOL DISTRICT'))
      expect(described_class.employer_key('CALIFORNIA NURSES'))
        .to eq(described_class.employer_key('CALIFORNIA NURSES ASSOCIATION'))
      expect(described_class.employer_key('ALAMEDA COUNTY COMPLETE COUNT COMMITTEE FOR CENSUS 2020'))
        .to eq(described_class.employer_key('ALAMEDA COUNTY'))
      expect(described_class.employer_key('CLAREMONT REALTOR'))
        .to eq(described_class.employer_key('CLAREMONT REALTY'))
      expect(described_class.employer_key('EDUCATE 78'))
        .to eq(described_class.employer_key('EDUCATE78'))
      expect(described_class.employer_key('TORRES LAW GROUP 1211 EMBARCADERO STE 210 OAKLAND CA 94606'))
        .to eq(described_class.employer_key('TORRES LAW GROUP'))
      expect(described_class.employer_key('OAKLAND UNIFIED SCHOOL DISTICT'))
        .to eq(described_class.employer_key('OAKLAND UNIFIED SCHOOL DISTRICT'))
      expect(described_class.employer_key('CITY OF OAKLAMD'))
        .to eq(described_class.employer_key('CITY OF OAKLAND'))
      expect(described_class.employer_key('TORRES LAW'))
        .to eq(described_class.employer_key('TORRES LAW GROUP'))
      expect(described_class.employer_key('MEYERS NAVE RIBACK SILVER & WILSON'))
        .to eq(described_class.employer_key('MEYERS NAVE'))
      expect(described_class.employer_key('ROCKWOOD LEADERSHIP INSTITUE'))
        .to eq(described_class.employer_key('ROCKWOOD LEADERSHIP INSTITUTE'))
      expect(described_class.employer_key('SIEGEL YEE'))
        .to eq(described_class.employer_key('SIEGEL & YEE'))
      expect(described_class.employer_key('ASPIRE'))
        .to eq(described_class.employer_key('ASPIRE PUBLIC SCHOOLS'))
      expect(described_class.employer_key('ROCKWOOD'))
        .to eq(described_class.employer_key('ROCKWOOD LEADERSHIP INSTITUTE'))
      expect(described_class.employer_key('META PLATFORMS'))
        .to eq(described_class.employer_key('META'))
      expect(described_class.employer_key('RIAZ'))
        .to eq(described_class.employer_key('RIAZ CAPITAL'))
      expect(described_class.employer_key('ALAMEDA HEALTH SYSTEMS'))
        .to eq(described_class.employer_key('ALAMEDA HEALTH SYSTEM'))
      expect(described_class.employer_key('BURKE WILLIAMS & SORENSON'))
        .to eq(described_class.employer_key('BURKE WILLIAMS & SORENSEN'))
      expect(described_class.employer_key('GENETECH'))
        .to eq(described_class.employer_key('GENENTECH'))
      expect(described_class.employer_key('OAKLAND RISING ACTION'))
        .to eq(described_class.employer_key('OAKLAND RISING'))
      expect(described_class.employer_key('SENECA'))
        .to eq(described_class.employer_key('SENECA FAMILY OF AGENCIES'))
      expect(described_class.employer_key('PERALTA'))
        .to eq(described_class.employer_key('PERALTA COMMUNITY COLLEGE DISTRICT'))
      expect(described_class.employer_key('MORGAN LEWIS & BOCKIUS'))
        .to eq(described_class.employer_key('MORGAN LEWIS'))
      expect(described_class.employer_key('UNIVERSITY OF CALIFORNIA OFFICE OF THE PRESIDENT'))
        .to eq(described_class.employer_key('UNIVERSITY OF CALIFORNIA'))
      expect(described_class.employer_key('PERALTA COMMUNITY COLLEGE'))
        .to eq(described_class.employer_key('PERALTA COMMUNITY COLLEGE DISTRICT'))
      expect(described_class.employer_key('LODESTAR K 5'))
        .to eq(described_class.employer_key('LODESTAR'))
      expect(described_class.employer_key('MILO GROUP'))
        .to eq(described_class.employer_key('MILO GROUP OF CALIFORNIA'))
      expect(described_class.employer_key('POLICY LINK'))
        .to eq(described_class.employer_key('POLICYLINK'))
      expect(described_class.employer_key('LIFELONG MEDICAL'))
        .to eq(described_class.employer_key('LIFELONG MEDICAL CARE'))
      expect(described_class.employer_key('KOS READ GROUP COMMUNICATIONS & PUBLIC AFFAIRS'))
        .to eq(described_class.employer_key('KOS READ GROUP'))
      expect(described_class.employer_key('MILLS COLLEGE AT NORTHEASTERN'))
        .to eq(described_class.employer_key('MILLS COLLEGE'))
      expect(described_class.employer_key('SALEFORCE'))
        .to eq(described_class.employer_key('SALESFORCE'))
      expect(described_class.employer_key('LIGHTHOUSE'))
        .to eq(described_class.employer_key('LIGHTHOUSE COMMUNITY CHARTER PUBLIC SCHOOLS'))
      expect(described_class.employer_key('DELOITTE CONSULTING'))
        .to eq(described_class.employer_key('DELOITTE'))
      expect(described_class.employer_key('GREAT OAKLAND PUBLIC SCHOOL LEADERSHIP CENTER'))
        .to eq(described_class.employer_key('GREAT OAKLAND PUBLIC SCHOOLS LEADERSHIP CENTER'))
      expect(described_class.employer_key('BART BAY AREA RAPID TRANSIT'))
        .to eq(described_class.employer_key('BART'))
      expect(described_class.employer_key('MCCONNEL GROUP'))
        .to eq(described_class.employer_key('MCCONNELL GROUP'))
      expect(described_class.employer_key('NATIONAL UNION OF HEALTHCARE WORKERS NUHW'))
        .to eq(described_class.employer_key('NATIONAL UNION OF HEALTHCARE WORKERS'))
      expect(described_class.employer_key('AKONADI'))
        .to eq(described_class.employer_key('AKONADI FOUNDATION'))
      expect(described_class.employer_key('FUSD'))
        .to eq(described_class.employer_key('Fremont Unified School District'))
      expect(described_class.employer_key('SUTTER'))
        .to eq(described_class.employer_key('SUTTER HEALTH'))
      expect(described_class.employer_key('SAN FRANCISCO STATE'))
        .to eq(described_class.employer_key('SAN FRANCISCO STATE UNIVERSITY'))
      expect(described_class.employer_key('COLDWELL BANKER REALTY'))
        .to eq(described_class.employer_key('COLDWELL BANKER'))
      expect(described_class.employer_key('UC BERKELEY CENTER FOR LABOR RESEARCH'))
        .to eq(described_class.employer_key('UC BERKELEY'))
      expect(described_class.employer_key('TIDES CENTER PODER'))
        .to eq(described_class.employer_key('TIDES CENTER'))
      expect(described_class.employer_key('STATE OF CALIFORNIA CAL OSHA'))
        .to eq(described_class.employer_key('STATE OF CALIFORNIA'))
      expect(described_class.employer_key('FARMERS INSURANCE RUTH STRUOP AGENCY'))
        .to eq(described_class.employer_key('FARMERS INSURANCE'))
      expect(described_class.employer_key('GREAT SCHOOL CHOICES'))
        .to eq(described_class.employer_key('GREAT SCHOOL VOICES'))
      expect(described_class.employer_key('ALAMEDA COUNTY IHSS'))
        .to eq(described_class.employer_key('ALAMEDA COUNTY'))
      expect(described_class.employer_key('COMPASS LEXECON'))
        .to eq(described_class.employer_key('COMPASS'))
      expect(described_class.employer_key('EDUCATION'))
        .to eq(described_class.employer_key('EDUCATION FOR CHANGE'))
      expect(described_class.employer_key('PLANNED PARENTHOOD'))
        .to eq(described_class.employer_key('PLANNED PARENTHOOD MAR MONTE'))
    end

    it 'merges spelled-out and abbreviated school districts' do
      # "<City> USD" is expanded generically
      {
        'Oakland USD' => 'Oakland Unified School District',
        'San Francisco USD' => 'San Francisco Unified School District',
        'Los Angeles USD' => 'Los Angeles Unified School District',
        'Piedmont USD' => 'Piedmont Unified School District',
        # Acronyms are aliased individually
        'SFUSD' => 'San Francisco Unified School District',
        'SF Unified School District' => 'San Francisco Unified School District',
        'LAUSD' => 'Los Angeles Unified School District',
        'BUSD' => 'Berkeley Unified School District',
        'HUSD' => 'Hayward Unified School District',
        'WCCUSD' => 'West Contra Costa Unified School District',
        'CVUSD' => 'Castro Valley Unified School District',
      }.each do |abbreviated, spelled_out|
        expect(described_class.employer_key(abbreviated))
          .to eq(described_class.employer_key(spelled_out)), abbreviated
      end

      # Different districts stay distinct
      expect(described_class.employer_key('San Francisco USD'))
        .not_to eq(described_class.employer_key('Oakland USD'))
    end

    it 'strips a trailing CA location tag' do
      expect(described_class.employer_key('City of Berkeley, CA'))
        .to eq(described_class.employer_key('City of Berkeley'))
      expect(described_class.employer_key('County of Alameda, CA'))
        .to eq(described_class.employer_key('County of Alameda'))
    end

    it 'keeps a trailing CA that is part of the name' do
      expect(described_class.employer_key('State of CA'))
        .to eq(described_class.employer_key('State of California'))
      expect(described_class.employer_key('ACLU of Northern CA'))
        .to eq(described_class.employer_key('ACLU of Northern California'))
      expect(described_class.employer_key('Engineers & Scientists of CA'))
        .to eq('ENGINEERS & SCIENTISTS OF CA')
      expect(described_class.employer_key('Blue Shield of California'))
        .to eq('BLUE SHIELD OF CALIFORNIA')
    end

    it 'buckets self-employment variants' do
      ['Self', 'SELF-EMPLOYED', 'Self Employed',
       'Self-Employed, No Separate Business Name',
       'No Separate Business Name', 'no seperate business name'].each do |variant|
        expect(described_class.employer_key(variant))
          .to eq(ContributorNameCoalescer::SELF_EMPLOYED)
      end
    end

    it 'buckets values as Unknown only when both fields are blank' do
      [nil, '', '  ', 'N/A', 'N.A.', 'None', 'Unknown'].each do |variant|
        expect(described_class.employer_key(variant))
          .to eq(ContributorNameCoalescer::UNKNOWN)
        expect(described_class.employer_key(variant, 'n/a'))
          .to eq(ContributorNameCoalescer::UNKNOWN)
      end
    end

    it 'infers no-employer status from the occupation when employer is blank' do
      {
        'Retired' => ContributorNameCoalescer::RETIRED_NOT_EMPLOYED,
        'retired teacher' => ContributorNameCoalescer::RETIRED_NOT_EMPLOYED,
        'Not Employed' => ContributorNameCoalescer::RETIRED_NOT_EMPLOYED,
        'unemployed' => ContributorNameCoalescer::RETIRED_NOT_EMPLOYED,
        'Homemaker' => ContributorNameCoalescer::HOMEMAKER,
        'Housewife' => ContributorNameCoalescer::HOMEMAKER,
        'Self-Employed' => ContributorNameCoalescer::SELF_EMPLOYED,
      }.each do |occupation, expected|
        expect(described_class.employer_key('', occupation))
          .to eq(expected), occupation
      end
    end

    it 'marks blank employers as not reported when the occupation is a real job' do
      ['Teacher', 'Attorney', 'Student'].each do |occupation|
        expect(described_class.employer_key(nil, occupation))
          .to eq(ContributorNameCoalescer::EMPLOYER_NOT_REPORTED), occupation
      end
    end

    it 'buckets retired and not-employed variants together' do
      ['Retired', 'Not Employed', 'unemployed', 'RETIRED TEACHER'].each do |variant|
        expect(described_class.employer_key(variant))
          .to eq(ContributorNameCoalescer::RETIRED_NOT_EMPLOYED), variant
      end
    end

    it 'merges City of Oakland variants and departments' do
      [
        'City Of Oakland, CA', 'The City of Oakland',
        "Oakland City Attorney's Office", 'Oakland City Council',
        'City of Oakland, Office of the City Attorney'
      ].each do |variant|
        expect(described_class.employer_key(variant))
          .to eq(described_class.employer_key('City of Oakland')), variant
      end
    end

    it 'separates Oakland Fire Department from the general city group' do
      ['Oakland Fire Department', 'Oakland Fire Dept.', 'Oakland Fire',
       'City Of Oakland Fire Department'].each do |variant|
        expect(described_class.employer_key(variant))
          .to eq(ContributorNameCoalescer::OAKLAND_FIRE), variant
      end

      ['Firefighter', 'FIRE FIGHTER', 'Fire Captain', 'Battalion Chief',
       'Engineer of Fire', 'Firefighter/Paramedic'].each do |occupation|
        expect(described_class.employer_key('City of Oakland', occupation))
          .to eq(ContributorNameCoalescer::OAKLAND_FIRE), occupation
      end

      # Firefighters often list just "Oakland" as their employer
      expect(described_class.employer_key('Oakland', 'Firefighter'))
        .to eq(ContributorNameCoalescer::OAKLAND_FIRE)
    end

    it 'separates Oakland Police Department from the general city group' do
      ['Oakland Police Department', 'Oakland Police Dept',
       'City of Oakland OPD'].each do |variant|
        expect(described_class.employer_key(variant))
          .to eq(ContributorNameCoalescer::OAKLAND_POLICE), variant
      end

      ['Police Officer', 'Sergeant', 'Police Lieutenant',
       'Deputy Chief of Police'].each do |occupation|
        expect(described_class.employer_key('City of Oakland', occupation))
          .to eq(ContributorNameCoalescer::OAKLAND_POLICE), occupation
      end
    end

    it 'separates the Alameda County DA from the general county group' do
      [
        'Alameda County DA', 'Alameda County District Attorney',
        'Alameda County District Attorneys Office',
        "Alameda County District Attorney's Office",
        'Alameda County District Attorney Office',
        'Alameda District Attorneys Office', 'DA Office',
        'Office Of The District Attorney Of Alameda'
      ].each do |variant|
        expect(described_class.employer_key(variant))
          .to eq(ContributorNameCoalescer::ALAMEDA_DA), variant
      end

      ['District Attorney', 'Deputy District Attorney',
       'Assistant District Attorney', 'DA Victim Witness'].each do |occupation|
        expect(described_class.employer_key('Alameda County', occupation))
          .to eq(ContributorNameCoalescer::ALAMEDA_DA), occupation
      end

      expect(described_class.employer_key('Alameda County', 'Social Worker'))
        .to eq(described_class.employer_key('Alameda County'))
      expect(described_class.employer_key("San Francisco District Attorney's Office"))
        .not_to eq(ContributorNameCoalescer::ALAMEDA_DA)
      expect(ContributorNameCoalescer::FIXED_DISPLAY_NAMES[ContributorNameCoalescer::ALAMEDA_DA])
        .to eq("Alameda County District Attorney's Office")
    end

    it 'keeps other city employees in the City of Oakland group' do
      ['Librarian', 'Councilmember', 'Deputy City Attorney', 'Mayor',
       'Analyst'].each do |occupation|
        expect(described_class.employer_key('City of Oakland', occupation))
          .to eq(described_class.employer_key('City of Oakland')), occupation
      end
    end

    it 'only reassigns fire/police occupations for City of Oakland employers' do
      expect(described_class.employer_key('Google', 'Firefighter'))
        .to eq('GOOGLE')
      expect(described_class.employer_key('City of Alameda', 'Firefighter'))
        .to eq(described_class.employer_key('City of Alameda'))
    end

    it 'does not merge distinct employers' do
      expect(described_class.employer_key('City of Oakland'))
        .not_to eq(described_class.employer_key('City of Alameda'))
    end
  end

  describe '.occupation_key' do
    it 'merges attorney variants' do
      ['Lawyer', 'ATTORNEY', 'Attorney at Law', 'attorney'].each do |variant|
        expect(described_class.occupation_key(variant)).to eq('ATTORNEY')
      end
    end

    it 'buckets retired and not-employed variants together' do
      ['Retired', 'Not Employed', 'unemployed'].each do |variant|
        expect(described_class.occupation_key(variant))
          .to eq(ContributorNameCoalescer::RETIRED_NOT_EMPLOYED), variant
      end
    end

    it 'merges Executive Director variants' do
      ['Exec Director', 'Exec. Dir.', 'ED', 'E.D.',
       'Executive Director, Oakland', 'Nonprofit Executive Director',
       'Non-Profit Executive Director', 'Interim Executive Director',
       'Co-Executive Director', 'President and Executive Director',
       'Founder & Executive Director', 'Founder and Executive Director',
       'Co-Founder & Executive Director',
       'Executive Directot', 'Exexcutive Director'].each do |variant|
        expect(described_class.occupation_key(variant))
          .to eq('EXECUTIVE DIRECTOR'), variant
      end
    end

    it 'keeps qualified Executive Director titles separate' do
      ['Assistant Executive Director', 'Executive Managing Director',
       'Executive'].each do |variant|
        expect(described_class.occupation_key(variant))
          .not_to eq('EXECUTIVE DIRECTOR'), variant
      end
    end

    it 'merges business-owner variants into the Owner group' do
      ['Business Owner', 'Small Business Owner', 'Co-Owner', 'Owners',
       'Owner/Manager', 'Owner/Operator', 'Restaurant Owner', 'Cafe Owner',
       'Bar Owner', 'Boutique Owner', 'Store Owner', 'Hotel Owner',
       'Gallery Owner', 'Agency Owner', 'Owner/Principal', 'Principal Owner',
       'GM/Owner'].each do |variant|
        expect(described_class.occupation_key(variant)).to eq('OWNER'), variant
      end
    end

    it 'keeps property and rental owners separate from the Owner group' do
      ['Property Owner', 'Rental Owner'].each do |variant|
        expect(described_class.occupation_key(variant)).not_to eq('OWNER'), variant
      end
      expect(described_class.occupation_key('Real Estate Property Owner'))
        .to eq(described_class.occupation_key('Property Owner'))
    end

    it 'gives the umbrella Real Estate group a fixed display name' do
      expect(described_class.occupation_key('Real Estate Broker')).to eq('REAL ESTATE')
      expect(ContributorNameCoalescer::FIXED_DISPLAY_NAMES['REAL ESTATE'])
        .to eq('Real Estate')
    end

    it 'applies curated aliases' do
      expect(described_class.occupation_key('Consulting'))
        .to eq(described_class.occupation_key('Consultant'))
      expect(described_class.occupation_key('RN'))
        .to eq(described_class.occupation_key('Registered Nurse'))
      expect(described_class.occupation_key('REAL ESTATE BROKER'))
        .to eq(described_class.occupation_key('REAL ESTATE'))
      expect(described_class.occupation_key('REAL ESTATE OWNER MANAGER'))
        .to eq(described_class.occupation_key('REAL ESTATE'))
      expect(described_class.occupation_key('REAL ESTATE DEVELOPER'))
        .to eq(described_class.occupation_key('REAL ESTATE'))
      expect(described_class.occupation_key('BUSINESS DEVELOPMENT'))
        .to eq(described_class.occupation_key('BUSINESS DEVELOPMENT MANAGER'))
      expect(described_class.occupation_key('REAL ESTATE CONSULTANT'))
        .to eq(described_class.occupation_key('REAL ESTATE'))
      expect(described_class.occupation_key('NURSE PRACTITIONER'))
        .to eq(described_class.occupation_key('NURSE'))
      expect(described_class.occupation_key('OPERATIONS'))
        .to eq(described_class.occupation_key('OPERATIONS MANAGER'))
      expect(described_class.occupation_key('SALES MANAGER'))
        .to eq(described_class.occupation_key('SALES'))
      expect(described_class.occupation_key('PUBLIC AFFAIRS'))
        .to eq(described_class.occupation_key('PUBLIC AFFAIRS CONSULTANT'))
      expect(described_class.occupation_key('EDUCATIONAL CONSULTANT'))
        .to eq(described_class.occupation_key('EDUCATION CONSULTANT'))
      expect(described_class.occupation_key('NONPROFIT DIRECTOR'))
        .to eq(described_class.occupation_key('NON PROFIT DIRECTOR'))
      expect(described_class.occupation_key('ACCOUNTING'))
        .to eq(described_class.occupation_key('ACCOUNTANT'))
      expect(described_class.occupation_key('NURSE MIDWIFE'))
        .to eq(described_class.occupation_key('NURSE'))
      expect(described_class.occupation_key('FINANCE MANAGER'))
        .to eq(described_class.occupation_key('FINANCE'))
      expect(described_class.occupation_key('SALES DIRECTOR'))
        .to eq(described_class.occupation_key('SALES'))
      expect(described_class.occupation_key('PROGRAMS MANAGER'))
        .to eq(described_class.occupation_key('PROGRAM MANAGER'))
      expect(described_class.occupation_key('GRAPHIC DESIGN'))
        .to eq(described_class.occupation_key('GRAPHIC DESIGNER'))
      expect(described_class.occupation_key('OWNER MANAGER'))
        .to eq(described_class.occupation_key('OWNER'))
      expect(described_class.occupation_key('SENIOR DIRECTOR OF INNOVATION AND LEARNING'))
        .to eq(described_class.occupation_key('SENIOR DIRECTOR'))
      expect(described_class.occupation_key('MARKETING MANAGER'))
        .to eq(described_class.occupation_key('MARKETING'))
      expect(described_class.occupation_key('REAL ESTATE MANAGER'))
        .to eq(described_class.occupation_key('REAL ESTATE'))
      expect(described_class.occupation_key('REAL ESTATE INVESTOR'))
        .to eq(described_class.occupation_key('REAL ESTATE'))
      expect(described_class.occupation_key('REAL ESTATE DEVELOPMENT'))
        .to eq(described_class.occupation_key('REAL ESTATE'))
      expect(described_class.occupation_key('COMMUNICATIONS STRATEGIST'))
        .to eq(described_class.occupation_key('COMMUNICATIONS'))
      expect(described_class.occupation_key('ADMINISTRATION'))
        .to eq(described_class.occupation_key('ADMINISTRATOR'))
      expect(described_class.occupation_key('REAL ESTATE INVESTMENT'))
        .to eq(described_class.occupation_key('REAL ESTATE'))
      expect(described_class.occupation_key('MANAGER OF EDUCATOR COMMUNITY'))
        .to eq(described_class.occupation_key('MANAGER'))
      expect(described_class.occupation_key('TEACHER LEADER'))
        .to eq(described_class.occupation_key('TEACHER'))
      expect(described_class.occupation_key('BUSINESS'))
        .to eq(described_class.occupation_key('BUSINESS OWNER'))
      expect(described_class.occupation_key('CREATIVE DIRECTION'))
        .to eq(described_class.occupation_key('CREATIVE DIRECTOR'))
      expect(described_class.occupation_key('MANAGER DIPR'))
        .to eq(described_class.occupation_key('MANAGER'))
      expect(described_class.occupation_key('EXECUTIVE DIRECTOR OF PROFESSIONAL LEARNING'))
        .to eq(described_class.occupation_key('EXECUTIVE DIRECTOR'))
      expect(described_class.occupation_key('MARKETING DIRECTOR'))
        .to eq(described_class.occupation_key('MARKETING'))
      expect(described_class.occupation_key('EXECUTIVE DIRECTOR OAKLAND'))
        .to eq(described_class.occupation_key('EXECUTIVE DIRECTOR'))
      expect(described_class.occupation_key('EDUCATION ASSOCIATE'))
        .to eq(described_class.occupation_key('EDUCATION'))
      expect(described_class.occupation_key('SALES ASSOCIATE'))
        .to eq(described_class.occupation_key('SALES'))
      expect(described_class.occupation_key('REAL ESTATE PROPERTY OWNER'))
        .to eq(described_class.occupation_key('PROPERTY OWNER'))
      expect(described_class.occupation_key('REAL ESTATE PROFESSIONAL'))
        .to eq(described_class.occupation_key('REAL ESTATE'))
      expect(described_class.occupation_key('RESEARCH'))
        .to eq(described_class.occupation_key('RESEARCHER'))
      expect(described_class.occupation_key('REAL ESTATE APPRAISER'))
        .to eq(described_class.occupation_key('REAL ESTATE'))
      expect(described_class.occupation_key('ASSOCIATE DIRECTOR OF MEDIA RELATIONS'))
        .to eq(described_class.occupation_key('ASSOCIATE DIRECTOR'))
      expect(described_class.occupation_key('EDUCATION POLICY'))
        .to eq(described_class.occupation_key('EDUCATION'))
      expect(described_class.occupation_key('ATTORNEY CONSULTANT'))
        .to eq(described_class.occupation_key('ATTORNEY'))
    end

    it 'merges spelled-out titles with their acronyms' do
      expect(described_class.occupation_key('Chief Executive Officer'))
        .to eq(described_class.occupation_key('C.E.O.'))
      expect(described_class.occupation_key('CEO')).to eq('CEO')
    end

    it 'merges President into the CEO group' do
      ['President', 'PRESIDENT', 'President & CEO', 'President/CEO',
       'President and CEO', 'CEO/President'].each do |variant|
        expect(described_class.occupation_key(variant)).to eq('CEO'), variant
      end
      expect(ContributorNameCoalescer::FIXED_DISPLAY_NAMES['CEO'])
        .to eq('Chief Executive Officer/President')
    end

    it 'merges founder-CEO combinations into the CEO group' do
      ['Founder & CEO', 'Founder/CEO', 'Founder and CEO', 'CEO & Founder',
       'Founder/Chief Executive Officer', 'Founder & Chief Executive Officer',
       'Co-Founder & CEO', 'CEO and Co-Founder',
       'Chief Executive Officer/Co-Founder'].each do |variant|
        expect(described_class.occupation_key(variant)).to eq('CEO'), variant
      end
    end

    it 'does not merge Vice President into the CEO group' do
      expect(described_class.occupation_key('Vice President')).not_to eq('CEO')
    end

    it 'does not merge distinct occupations' do
      expect(described_class.occupation_key('Teacher'))
        .not_to eq(described_class.occupation_key('Professor'))
    end

    it 'keeps qualified occupations separate from the base occupation' do
      expect(described_class.occupation_key('Deputy City Attorney'))
        .not_to eq(described_class.occupation_key('Attorney'))
    end

    it 'infers no-employment status from the employer when occupation is blank' do
      expect(described_class.occupation_key('', 'Retired'))
        .to eq(ContributorNameCoalescer::RETIRED_NOT_EMPLOYED)
      expect(described_class.occupation_key(nil, 'Not Employed'))
        .to eq(ContributorNameCoalescer::RETIRED_NOT_EMPLOYED)
      expect(described_class.occupation_key('', 'Self-Employed'))
        .to eq(ContributorNameCoalescer::SELF_EMPLOYED)
    end

    it 'marks blank occupations as not reported when the employer is real' do
      expect(described_class.occupation_key('', 'Google'))
        .to eq(ContributorNameCoalescer::OCCUPATION_NOT_REPORTED)
    end

    it 'stays Unknown when both fields are blank' do
      expect(described_class.occupation_key(nil, ''))
        .to eq(ContributorNameCoalescer::UNKNOWN)
    end
  end
end
