.PHONY: clean import

CD := $(shell pwd)

clean:
	rm -rf inputs/*.csv downloads/*

process: process.rb
	rm -rf build && ruby process.rb

import: inputs/efile_COAK_2016_A-Contributions.csv inputs/oakland_candidates.csv \
	inputs/oakland_committees.csv inputs/oakland_referendums.csv
	dropdb disclosure-backend || true
	createdb disclosure-backend
	csvsql --db postgresql:///disclosure-backend --insert inputs/efile_COAK_2016_*.csv
	csvsql --doublequote --db postgresql:///disclosure-backend --insert inputs/oakland_candidates.csv
	echo 'ALTER TABLE "oakland_candidates" ADD COLUMN id SERIAL PRIMARY KEY;' | psql disclosure-backend
	csvsql --doublequote --db postgresql:///disclosure-backend --insert inputs/oakland_referendums.csv
	echo 'ALTER TABLE "oakland_referendums" ADD COLUMN id SERIAL PRIMARY KEY;' | psql disclosure-backend
	csvsql --doublequote --db postgresql:///disclosure-backend --insert inputs/oakland_committees.csv
	echo 'ALTER TABLE "oakland_committees" ADD COLUMN id SERIAL PRIMARY KEY;' | psql disclosure-backend
	echo 'CREATE TABLE "office_elections" (id SERIAL PRIMARY KEY, name VARCHAR(255));' | psql disclosure-backend
	echo 'CREATE TABLE "calculations" (id SERIAL PRIMARY KEY, subject_id integer, subject_type varchar(30), name varchar(40), value jsonb);' | psql disclosure-backend

inputs/efile_COAK_%_A-Contributions.csv: downloads/efile_COAK_%.xlsx
	ssconvert -S $< inputs/$(subst .xlsx,_%s.csv,$(shell basename $<))

downloads/efile_COAK_%.xlsx: downloads/efile_COAK_%.zip
	 unzip -p $< > $@

downloads/efile_COAK_%.zip:
	wget -O $@ http://nf4.netfile.com/pub2/excel/COAKBrowsable/$(shell basename $@)

inputs/oakland_candidates.csv:
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/1272oaLyQhKwQa6RicA5tBso6wFruum-mgrNm3O3VogI/pub?gid=0&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

inputs/oakland_referendums.csv:
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/1272oaLyQhKwQa6RicA5tBso6wFruum-mgrNm3O3VogI/pub?gid=1693935349&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

inputs/oakland_committees.csv:
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/1272oaLyQhKwQa6RicA5tBso6wFruum-mgrNm3O3VogI/pub?gid=1995437960&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@
