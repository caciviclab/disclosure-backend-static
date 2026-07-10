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
        'Kaiser Permanente Oakland Medical Center', 'Kaiser Permante'
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
        'Retired' => ContributorNameCoalescer::RETIRED,
        'retired teacher' => ContributorNameCoalescer::RETIRED,
        'Not Employed' => ContributorNameCoalescer::NOT_EMPLOYED,
        'unemployed' => ContributorNameCoalescer::NOT_EMPLOYED,
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

    it 'buckets retired and not-employed variants' do
      expect(described_class.employer_key('Retired'))
        .to eq(ContributorNameCoalescer::RETIRED)
      expect(described_class.employer_key('Not Employed'))
        .to eq(ContributorNameCoalescer::NOT_EMPLOYED)
      expect(described_class.employer_key('unemployed'))
        .to eq(ContributorNameCoalescer::NOT_EMPLOYED)
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

    it 'merges spelled-out titles with their acronyms' do
      expect(described_class.occupation_key('Chief Executive Officer'))
        .to eq(described_class.occupation_key('C.E.O.'))
      expect(described_class.occupation_key('CEO')).to eq('CEO')
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
        .to eq(ContributorNameCoalescer::RETIRED)
      expect(described_class.occupation_key(nil, 'Not Employed'))
        .to eq(ContributorNameCoalescer::NOT_EMPLOYED)
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
