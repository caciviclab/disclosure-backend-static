.PHONY: download clean import run

CD := $(shell pwd)

clean:
	rm -rf downloads/*

process: process.rb
	rm -rf build && ruby process.rb

download: downloads/csv/oakland_candidates.csv downloads/csv/oakland_committees.csv \
	downloads/csv/oakland_referendums.csv downloads/csv/oakland_name_to_number.csv \
	download-2015 download-2016 download-2017

download-%:
	mkdir -p downloads/raw
	wget -O downloads/raw/efile_COAK_$(subst download-,,$@).zip --no-verbose \
		http://nf4.netfile.com/pub2/excel/COAKBrowsable/efile_COAK_$(subst download-,,$@).zip
	unzip -p downloads/raw/efile_COAK_$(subst download-,,$@).zip > downloads/raw/efile_COAK_$(subst download-,,$@).xlsx
	ruby ssconvert.rb downloads/raw/efile_COAK_$(subst download-,,$@).xlsx 'downloads/csv/efile_COAK_$(subst download-,,$@)_%{sheet}.csv'

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
	echo 'CREATE TABLE "office_elections" (id SERIAL PRIMARY KEY, name VARCHAR(255));' | psql disclosure-backend
	echo 'CREATE TABLE "calculations" (id SERIAL PRIMARY KEY, subject_id integer, subject_type varchar(30), name varchar(40), value jsonb);' | psql disclosure-backend
	./make_view.sh
	./remove_duplicate_transactions.sh

dropdb:
	dropdb disclosure-backend || true

createdb:
	createdb disclosure-backend

496 497 A-Contributions B1-Loans B2-Loans C-Contributions D-Expenditure E-Expenditure F-Expenses F461P5-Expenditure F465P3-Expenditure F496P3-Contributions G-Expenditure H-Loans I-Contributions Summary:
	./load.sh $@
	./clean.sh $@
	./latest_only.sh $@

downloads/csv/oakland_candidates.csv:
	mkdir -p downloads/csv
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vSeuPY8huhnstJAKOoFNzwGCuTXMX6DhBU5hVVPIYmIBRLzHMGAPC2N7665gsT3F9LuLaRcBGDP4jm5/pub?gid=222087091&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/oakland_referendums.csv:
	mkdir -p downloads/csv
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vSeuPY8huhnstJAKOoFNzwGCuTXMX6DhBU5hVVPIYmIBRLzHMGAPC2N7665gsT3F9LuLaRcBGDP4jm5/pub?gid=831424275&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/oakland_name_to_number.csv:
	mkdir -p downloads/csv
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/1272oaLyQhKwQa6RicA5tBso6wFruum-mgrNm3O3VogI/pub?gid=896561174&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/oakland_committees.csv:
	mkdir -p downloads/csv
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/1272oaLyQhKwQa6RicA5tBso6wFruum-mgrNm3O3VogI/pub?gid=1995437960&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

run:
	bundle exec ruby server.rb
