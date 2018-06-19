.PHONY: download clean import run

CD := $(shell pwd)

clean:
	rm -rf downloads/raw downloads/csv

process: process.rb
	rm -rf build && ruby process.rb

download-cached:
	wget -O- https://s3-us-west-2.amazonaws.com/odca-data-cache/$(shell \
		git log --author 'OpenDisclosure Deploybot' -n1 --pretty=format:%aI | cut -d"T" -f1 \
	).tar.gz | tar xz

upload-cache:
	tar czf - downloads/csv downloads/static \
		| aws s3 cp - s3://odca-data-cache/$(shell date +%Y-%m-%d).tar.gz --acl public-read

download: downloads/csv/oakland_candidates.csv downloads/csv/oakland_committees.csv \
	downloads/csv/oakland_referendums.csv downloads/csv/oakland_name_to_number.csv \
	download-SFO-2017 download-SFO-2018 \
	download-COAK-2015 download-COAK-2016 download-COAK-2017 download-COAK-2018 \
	download-BRK-2017 download-BRK-2018

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

download-BRK-%:
	ruby ssconvert.rb downloads/static/efile_BRK_$(subst download-BRK-,,$@).xlsx 'downloads/csv/efile_BRK_$(subst download-BRK-,,$@)_%{sheet}.csv'

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

downloads/csv/oakland_candidates.csv:
	mkdir -p downloads/csv downloads/raw
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=0&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/oakland_referendums.csv:
	mkdir -p downloads/csv downloads/raw
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=608094632&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/oakland_name_to_number.csv:
	mkdir -p downloads/csv
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=102954444&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

downloads/csv/oakland_committees.csv:
	mkdir -p downloads/csv
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/e/2PACX-1vRZNbqOzI3TlelO3OSh7QGC1Y4rofoRPs0TefWDLJvleFkaXq_6CSWgX89HfxLYrHhy0lr4QqUEryuc/pub?gid=145882925&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

run:
	bundle exec ruby server.rb
