.PHONY: download clean import run

CD := $(shell pwd)

clean:
	rm -rf downloads/*

process: process.rb
	rm -rf build && ruby process.rb

download: downloads/csv/oakland_candidates.csv downloads/csv/oakland_committees.csv \
	downloads/csv/oakland_referendums.csv downloads/csv/oakland_name_to_number.csv \
	download-SFO-2017 download-SFO-2018 \
	download-COAK-2015 download-COAK-2016 download-COAK-2017

download-SFO-%:
	mkdir -p downloads/raw
	wget -O downloads/raw/efile_SFO_$(subst download-SFO-,,$@).zip --no-verbose \
		http://nf4.netfile.com/pub2/excel/SFOBrowsable/efile_SFO_$(subst download-SFO-,,$@).zip
	unzip -p downloads/raw/efile_SFO_$(subst download-SFO-,,$@).zip > downloads/raw/efile_SFO_$(subst download-SFO-,,$@).xlsx
	ruby ssconvert.rb downloads/raw/efile_SFO_$(subst download-SFO-,,$@).xlsx 'downloads/csv/efile_SFO_$(subst download-SFO-,,$@)_%{sheet}.csv'

download-COAK-%:
	mkdir -p downloads/raw
	wget -O downloads/raw/efile_COAK_$(subst download-COAK-,,$@).zip --no-verbose \
		http://nf4.netfile.com/pub2/excel/COAKBrowsable/efile_COAK_$(subst download-COAK-,,$@).zip
	unzip -p downloads/raw/efile_COAK_$(subst download-COAK-,,$@).zip > downloads/raw/efile_COAK_$(subst download-COAK-,,$@).xlsx
	ruby ssconvert.rb downloads/raw/efile_COAK_$(subst download-COAK-,,$@).xlsx 'downloads/csv/efile_COAK_$(subst download-COAK-,,$@)_%{sheet}.csv'

import: dropdb createdb 496 497 A-Contributions B1-Loans B2-Loans C-Contributions \
		D-Expenditure E-Expenditure F-Expenses F461P5-Expenditure F465P3-Expenditure \
		F496P3-Contributions G-Expenditure H-Loans I-Contributions Summary
	csvsql --doublequote --db postgresql:///disclosure-backend --insert downloads/csv/oakland_candidates.csv
	echo 'ALTER TABLE "oakland_candidates" ADD COLUMN id SERIAL PRIMARY KEY;' | psql disclosure-backend
	csvsql --doublequote --db postgresql:///disclosure-backend --insert downloads/csv/oakland_referendums.csv
	echo 'ALTER TABLE "oakland_referendums" ADD COLUMN id SERIAL PRIMARY KEY;' | psql disclosure-backend
	csvsql --doublequote --db postgresql:///disclosure-backend --insert downloads/csv/oakland_name_to_number.csv
	csvsql --doublequote --db postgresql:///disclosure-backend --insert downloads/csv/oakland_committees.csv
	echo 'ALTER TABLE "oakland_committees" ADD COLUMN id SERIAL PRIMARY KEY;' | psql disclosure-backend
	echo 'CREATE TABLE "office_elections" (id SERIAL PRIMARY KEY, name VARCHAR(255), election_name VARCHAR(255));' | psql disclosure-backend
	echo 'CREATE TABLE "calculations" (id SERIAL PRIMARY KEY, subject_id integer, subject_type varchar(30), name varchar(40), value jsonb);' | psql disclosure-backend
	./bin/make_view
	./bin/remove_duplicate_transactions

dropdb:
	dropdb disclosure-backend || true

createdb:
	createdb disclosure-backend

496 497 A-Contributions B1-Loans B2-Loans C-Contributions D-Expenditure E-Expenditure F-Expenses F461P5-Expenditure F465P3-Expenditure F496P3-Contributions G-Expenditure H-Loans I-Contributions Summary:
	csvstack downloads/csv/efile_*_$@.csv | csvsql --db postgresql:///disclosure-backend --tables $@ --insert
	./bin/clean $@
	./bin/latest_only $@

downloads/csv/oakland_candidates.csv: bin/auto-detect-candidates
	mkdir -p downloads/csv downloads/raw
	# 2016 candidates
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vSeuPY8huhnstJAKOoFNzwGCuTXMX6DhBU5hVVPIYmIBRLzHMGAPC2N7665gsT3F9LuLaRcBGDP4jm5/pub?gid=0&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > downloads/raw/oakland_candidates_2016.csv
	# 2018 candidates
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vSeuPY8huhnstJAKOoFNzwGCuTXMX6DhBU5hVVPIYmIBRLzHMGAPC2N7665gsT3F9LuLaRcBGDP4jm5/pub?gid=222087091&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > downloads/raw/oakland_candidates_2018.csv
	# make a fake entry for SF candidates
	bin/auto-detect-candidates sf-june-2018 > downloads/raw/sf_candidates_june_2018.csv
	# combine the two years' candidates, adding an "election_name" column so we
	#   can differentiate later.
	csvstack -n election_name -g oakland-2016,oakland-2018,sf-june-2018 \
		downloads/raw/oakland_candidates_2016.csv \
		downloads/raw/oakland_candidates_2018.csv \
		downloads/raw/sf_candidates_june_2018.csv \
		> $@

downloads/csv/oakland_referendums.csv:
	mkdir -p downloads/csv downloads/raw
	# 2016 referendums
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vSeuPY8huhnstJAKOoFNzwGCuTXMX6DhBU5hVVPIYmIBRLzHMGAPC2N7665gsT3F9LuLaRcBGDP4jm5/pub?gid=1693935349&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > downloads/raw/oakland_referendums_2016.csv
	# 2018 referendums
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vSeuPY8huhnstJAKOoFNzwGCuTXMX6DhBU5hVVPIYmIBRLzHMGAPC2N7665gsT3F9LuLaRcBGDP4jm5/pub?gid=831424275&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > downloads/raw/oakland_referendums_2018.csv
	# combine the two years' referendums, adding an "election_name" column so we
	#   can differentiate later.
	csvstack -n election_name -g oakland-2016,oakland-2018 \
		downloads/raw/oakland_referendums_2016.csv \
		downloads/raw/oakland_referendums_2018.csv > $@

downloads/csv/oakland_name_to_number.csv:
	mkdir -p downloads/csv
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/1272oaLyQhKwQa6RicA5tBso6wFruum-mgrNm3O3VogI/pub?gid=896561174&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/oakland_committees.csv:
	mkdir -p downloads/csv
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vSeuPY8huhnstJAKOoFNzwGCuTXMX6DhBU5hVVPIYmIBRLzHMGAPC2N7665gsT3F9LuLaRcBGDP4jm5/pub?gid=387884938&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

run:
	bundle exec ruby server.rb
