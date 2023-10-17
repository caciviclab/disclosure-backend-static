.PHONY: download clean import run

DATABASE_NAME?=disclosure-backend
CSV_PATH?=downloads/csv

CD := $(shell pwd)
WGET=bin/wget-wrapper --no-verbose --tries=3

clean-spreadsheets:
	rm -rf downloads/csv/*.csv  downloads/csv/office_elections.csv  downloads/csv/measure_committees.csv downloads/csv/elections.csv

clean:
	rm -rf downloads/raw downloads/csv

process: process.rb
	# todo: remove RUBYOPT variable when activerecord fixes deprecation warnings
	echo 'delete from calculations;'| psql $(DATABASE_NAME)
	rm -rf build && RUBYOPT="-W:no-deprecated -W:no-experimental" bundle exec ruby process.rb

download-spreadsheets: downloads/csv/candidates.csv downloads/csv/committees.csv \
	downloads/csv/referendums.csv downloads/csv/name_to_number.csv \
	downloads/csv/office_elections.csv downloads/csv/elections.csv

download-cached:
	$(WGET) -O- "https://s3-us-west-2.amazonaws.com/odca-data-cache/$(shell \
		git log --author 'OpenDisclosure Deploybot' -n1 --pretty=format:%aI | cut -d"T" -f1 \
	).tar.gz" | tar xz

upload-cache:
	mkdir -p downloads/cached-db/
	pg_dump $(DATABASE_NAME) > downloads/cached-db/$(DATABASE_NAME).sql
	tar czf - downloads/csv downloads/static downloads/cached-db \
		| aws s3 cp - s3://odca-data-cache/$(shell date +%Y-%m-%d).tar.gz --acl public-read

download: download-spreadsheets \
	download-COAK-2014 download-COAK-2015 download-COAK-2016 \
	download-COAK-2017 download-COAK-2018 \
	download-COAK-2019 download-COAK-2020 \
	download-COAK-2021 download-COAK-2022 \
	download-COAK-2023

download-SFO-%:
	mkdir -p downloads/raw
	$(WGET) http://nf4.netfile.com/pub2/excel/SFOBrowsable/efile_SFO_$(subst download-SFO-,,$@).zip -O \
		downloads/raw/efile_SFO_$(subst download-SFO-,,$@).zip
	unzip -p downloads/raw/efile_SFO_$(subst download-SFO-,,$@).zip > downloads/raw/efile_SFO_$(subst download-SFO-,,$@).xlsx
	ruby ssconvert.rb downloads/raw/efile_SFO_$(subst download-SFO-,,$@).xlsx 'downloads/csv/efile_SFO_$(subst download-SFO-,,$@)_%{sheet}.csv'

download-COAK-%:
	mkdir -p downloads/raw
	$(WGET) http://nf4.netfile.com/pub2/excel/COAKBrowsable/efile_newest_COAK_$(subst download-COAK-,,$@).zip -O \
		downloads/raw/efile_COAK_$(subst download-COAK-,,$@).zip
	unzip -p downloads/raw/efile_COAK_$(subst download-COAK-,,$@).zip > downloads/raw/efile_COAK_$(subst download-COAK-,,$@).xlsx
	ruby ssconvert.rb downloads/raw/efile_COAK_$(subst download-COAK-,,$@).xlsx 'downloads/csv/efile_COAK_$(subst download-COAK-,,$@)_%{sheet}.csv'

download-BRK-%:
	ruby ssconvert.rb downloads/static/efile_BRK_$(subst download-BRK-,,$@).xlsx 'downloads/csv/efile_BRK_$(subst download-BRK-,,$@)_%{sheet}.csv'

import: recreatedb
	$(MAKE) do-import-spreadsheets
	$(MAKE) import-data

import-cached: recreatedb
	cat downloads/cached-db/$(DATABASE_NAME).sql | psql $(DATABASE_NAME)

import-spreadsheets: prep-import-spreadsheets do-import-spreadsheets
	./bin/make_view

prep-import-spreadsheets:
	echo 'DROP VIEW "Measure_Expenditures";' | psql $(DATABASE_NAME)
	echo 'DROP VIEW "all_contributions" CASCADE;' | psql $(DATABASE_NAME)
	echo 'DROP VIEW "independent_candidate_expenditures";' | psql $(DATABASE_NAME)


do-import-spreadsheets:
	echo 'DROP TABLE IF EXISTS candidates;' | psql $(DATABASE_NAME)
	csvsql --doublequote --db postgresql:///$(DATABASE_NAME) --insert $(CSV_PATH)/candidates.csv
	echo 'ALTER TABLE "candidates" ADD COLUMN id SERIAL PRIMARY KEY;' | psql $(DATABASE_NAME)
	echo 'DROP TABLE IF EXISTS referendums;' | psql $(DATABASE_NAME)
	csvsql --doublequote --db postgresql:///$(DATABASE_NAME) --insert $(CSV_PATH)/referendums.csv
	echo 'ALTER TABLE "referendums" ADD COLUMN id SERIAL PRIMARY KEY;' | psql $(DATABASE_NAME)
	echo 'DROP TABLE IF EXISTS name_to_number;' | psql $(DATABASE_NAME)
	csvsql --doublequote --db postgresql:///$(DATABASE_NAME) --insert $(CSV_PATH)/name_to_number.csv
	echo 'DROP TABLE IF EXISTS committees;' | psql $(DATABASE_NAME)
	csvsql --doublequote --db postgresql:///$(DATABASE_NAME) --insert $(CSV_PATH)/committees.csv
	echo 'ALTER TABLE "committees" ADD COLUMN id SERIAL PRIMARY KEY;' | psql $(DATABASE_NAME)
	echo 'DROP TABLE IF EXISTS office_elections;' | psql $(DATABASE_NAME)
	csvsql --doublequote --db postgresql:///$(DATABASE_NAME) --insert downloads/csv/office_elections.csv
	echo 'ALTER TABLE "office_elections" ALTER COLUMN title TYPE varchar(50);' | psql $(DATABASE_NAME)
	echo 'ALTER TABLE "office_elections" ADD COLUMN id SERIAL PRIMARY KEY;' | psql $(DATABASE_NAME)
	echo 'DROP TABLE IF EXISTS elections;' | psql $(DATABASE_NAME)
	csvsql --doublequote --db postgresql:///$(DATABASE_NAME) --insert downloads/csv/elections.csv
	echo 'ALTER TABLE "elections" ADD COLUMN id SERIAL PRIMARY KEY;' | psql $(DATABASE_NAME)

import-data: 496 497 A-Contributions B1-Loans B2-Loans C-Contributions \
	D-Expenditure E-Expenditure F-Expenses F461P5-Expenditure F465P3-Expenditure \
	F496P3-Contributions G-Expenditure H-Loans I-Contributions Summary
	echo 'CREATE TABLE IF NOT EXISTS "calculations" (id SERIAL PRIMARY KEY, subject_id integer, subject_type varchar(30), name varchar(40), value jsonb);' | psql $(DATABASE_NAME)
	./bin/remove_duplicate_transactions
	./bin/make_view

recreatedb:
	dropdb $(DATABASE_NAME) || true
	createdb $(DATABASE_NAME) --lc-collate=C --template=template0

reindex:
	ruby search_index.rb

496 497 A-Contributions B1-Loans B2-Loans C-Contributions D-Expenditure E-Expenditure F-Expenses F461P5-Expenditure F465P3-Expenditure F496P3-Contributions G-Expenditure H-Loans I-Contributions Summary:
	DATABASE_NAME=$(DATABASE_NAME) ./bin/import-file $(CSV_PATH) $@

downloads/csv/candidates.csv:
	mkdir -p downloads/csv downloads/raw
	$(WGET) -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=0&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/office_elections.csv:
	mkdir -p downloads/csv downloads/raw
	$(WGET) -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=585313505&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/referendums.csv:
	mkdir -p downloads/csv downloads/raw
	$(WGET) -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=608094632&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/name_to_number.csv:
	mkdir -p downloads/csv
	$(WGET) -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=102954444&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/committees.csv:
	mkdir -p downloads/csv
	$(WGET) -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=1015408103&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/elections.csv:
	mkdir -p downloads/csv
	$(WGET) -O- \
		'https://docs.google.com/spreadsheets/d/1vJR8GR5Bk3bUQXziPiQe7to1O-QEm-_5GfD7hPjp-Xc/pub?gid=2138925841&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

run:
	bundle exec ruby server.rb
