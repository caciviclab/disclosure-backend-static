.PHONY: download clean import run

DATABASE_NAME?=disclosure-backend
CSV_PATH?=downloads/csv

CD := $(shell pwd)
WGET=bin/wget-wrapper -O- --no-verbose --tries=3

clean-spreadsheets:
	rm -rf downloads/csv/oakland_*.csv office_elections.csv measure_committees.csv

clean:
	rm -rf downloads/raw downloads/csv

process: process.rb
	rm -rf build && ruby process.rb

download-spreadsheets: downloads/csv/oakland_candidates.csv downloads/csv/oakland_committees.csv \
	downloads/csv/oakland_referendums.csv downloads/csv/oakland_name_to_number.csv \
	downloads/csv/office_elections.csv downloads/csv/elections.csv

download-cached:
	$(WGET) "https://s3-us-west-2.amazonaws.com/odca-data-cache/$(shell \
		git log --author 'OpenDisclosure Deploybot' -n1 --pretty=format:%aI | cut -d"T" -f1 \
	).tar.gz" | tar xz

upload-cache:
	mkdir -p downloads/cached-db/
	pg_dump $(DATABASE_NAME) > downloads/cached-db/$(DATABASE_NAME).sql
	tar czf - downloads/csv downloads/static downloads/cached-db \
		| aws s3 cp - s3://odca-data-cache/$(shell date +%Y-%m-%d).tar.gz --acl public-read

download: download-spreadsheets download-SFO-2017 download-SFO-2018 \
	download-COAK-2015 download-COAK-2016 download-COAK-2017 download-COAK-2018 \
	download-BRK-2017 download-BRK-2018

download-SFO-%:
	mkdir -p downloads/raw
	$(WGET) http://nf4.netfile.com/pub2/excel/SFOBrowsable/efile_SFO_$(subst download-SFO-,,$@).zip > \
		downloads/raw/efile_SFO_$(subst download-SFO-,,$@).zip
	unzip -p downloads/raw/efile_SFO_$(subst download-SFO-,,$@).zip > downloads/raw/efile_SFO_$(subst download-SFO-,,$@).xlsx
	ruby ssconvert.rb downloads/raw/efile_SFO_$(subst download-SFO-,,$@).xlsx 'downloads/csv/efile_SFO_$(subst download-SFO-,,$@)_%{sheet}.csv'

download-COAK-%:
	mkdir -p downloads/raw
	$(WGET) http://nf4.netfile.com/pub2/excel/COAKBrowsable/efile_COAK_$(subst download-COAK-,,$@).zip > \
		downloads/raw/efile_COAK_$(subst download-COAK-,,$@).zip
	unzip -p downloads/raw/efile_COAK_$(subst download-COAK-,,$@).zip > downloads/raw/efile_COAK_$(subst download-COAK-,,$@).xlsx
	ruby ssconvert.rb downloads/raw/efile_COAK_$(subst download-COAK-,,$@).xlsx 'downloads/csv/efile_COAK_$(subst download-COAK-,,$@)_%{sheet}.csv'

download-BRK-%:
	ruby ssconvert.rb downloads/static/efile_BRK_$(subst download-BRK-,,$@).xlsx 'downloads/csv/efile_BRK_$(subst download-BRK-,,$@)_%{sheet}.csv'

import: dropdb createdb do-import-spreadsheets import-data

import-cached: dropdb createdb
	cat downloads/cached-db/$(DATABASE_NAME).sql | psql $(DATABASE_NAME)

import-spreadsheets: prep-import-spreadsheets do-import-spreadsheets
	./bin/make_view

prep-import-spreadsheets:
	echo 'DROP VIEW "Measure_Expenditures";' | psql $(DATABASE_NAME)
	echo 'DROP VIEW "all_contributions" CASCADE;' | psql $(DATABASE_NAME)
	echo 'DROP VIEW "independent_candidate_expenditures";' | psql $(DATABASE_NAME)


do-import-spreadsheets:
	echo 'DROP TABLE IF EXISTS oakland_candidates;' | psql $(DATABASE_NAME)
	csvsql --doublequote --db postgresql:///$(DATABASE_NAME) --insert $(CSV_PATH)/oakland_candidates.csv
	echo 'ALTER TABLE "oakland_candidates" ADD COLUMN id SERIAL PRIMARY KEY;' | psql $(DATABASE_NAME)
	echo 'DROP TABLE IF EXISTS oakland_referendums;' | psql $(DATABASE_NAME)
	csvsql --doublequote --db postgresql:///$(DATABASE_NAME) --insert $(CSV_PATH)/oakland_referendums.csv
	echo 'ALTER TABLE "oakland_referendums" ADD COLUMN id SERIAL PRIMARY KEY;' | psql $(DATABASE_NAME)
	echo 'DROP TABLE IF EXISTS oakland_name_to_number;' | psql $(DATABASE_NAME)
	csvsql --doublequote --db postgresql:///$(DATABASE_NAME) --insert $(CSV_PATH)/oakland_name_to_number.csv
	echo 'DROP TABLE IF EXISTS oakland_committees;' | psql $(DATABASE_NAME)
	csvsql --doublequote --db postgresql:///$(DATABASE_NAME) --insert $(CSV_PATH)/oakland_committees.csv
	echo 'ALTER TABLE "oakland_committees" ADD COLUMN id SERIAL PRIMARY KEY;' | psql $(DATABASE_NAME)
	echo 'DROP TABLE IF EXISTS office_elections;' | psql $(DATABASE_NAME)
	csvsql --doublequote --db postgresql:///$(DATABASE_NAME) --insert downloads/csv/office_elections.csv
	echo 'ALTER TABLE "office_elections" ADD COLUMN id SERIAL PRIMARY KEY;' | psql $(DATABASE_NAME)
	echo 'DROP TABLE IF EXISTS elections;' | psql $(DATABASE_NAME)
	csvsql --doublequote --db postgresql:///$(DATABASE_NAME) --insert downloads/csv/elections.csv
	echo 'ALTER TABLE "elections" ADD COLUMN id SERIAL PRIMARY KEY;' | psql $(DATABASE_NAME)

import-data: 496 497 A-Contributions B1-Loans B2-Loans C-Contributions \
	D-Expenditure E-Expenditure F-Expenses F461P5-Expenditure F465P3-Expenditure \
	F496P3-Contributions G-Expenditure H-Loans I-Contributions Summary
	echo 'CREATE TABLE "calculations" (id SERIAL PRIMARY KEY, subject_id integer, subject_type varchar(30), name varchar(40), value jsonb);' | psql $(DATABASE_NAME)
	./bin/remove_duplicate_transactions
	./bin/make_view

dropdb:
	dropdb $(DATABASE_NAME) || true

createdb:
	createdb $(DATABASE_NAME)

496 497 A-Contributions B1-Loans B2-Loans C-Contributions D-Expenditure E-Expenditure F-Expenses F461P5-Expenditure F465P3-Expenditure F496P3-Contributions G-Expenditure H-Loans I-Contributions Summary:
	DATABASE_NAME=$(DATABASE_NAME) ./bin/import-file $(CSV_PATH) $@

downloads/csv/oakland_candidates.csv:
	mkdir -p downloads/csv downloads/raw
	$(WGET) \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=0&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/office_elections.csv:
	mkdir -p downloads/csv downloads/raw
	$(WGET) \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=585313505&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/oakland_referendums.csv:
	mkdir -p downloads/csv downloads/raw
	$(WGET) \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=608094632&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/oakland_name_to_number.csv:
	mkdir -p downloads/csv
	$(WGET) \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=102954444&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/oakland_committees.csv:
	mkdir -p downloads/csv
	$(WGET) \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=1015408103&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/elections.csv:
	mkdir -p downloads/csv
	$(WGET) \
		'https://docs.google.com/spreadsheets/d/1vJR8GR5Bk3bUQXziPiQe7to1O-QEm-_5GfD7hPjp-Xc/pub?gid=2138925841&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

run:
	bundle exec ruby server.rb
