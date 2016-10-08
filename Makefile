.PHONY: clean import

CD := $(shell pwd)

clean:
	rm -rf inputs/*.csv downloads/*

process: process.rb
	rm -rf build && ruby process.rb

import: inputs/efile_COAK_2016_A-Contributions.csv inputs/oakland_candidates.csv \
	inputs/oakland_committees.csv inputs/oakland_referendums.csv inputs/oakland_name_to_number.csv
	dropdb disclosure-backend || true
	createdb disclosure-backend
	csvsql --db postgresql:///disclosure-backend --insert inputs/efile_COAK_2016_*.csv
	csvsql --doublequote --db postgresql:///disclosure-backend --insert inputs/oakland_candidates.csv
	echo 'ALTER TABLE "oakland_candidates" ADD COLUMN id SERIAL PRIMARY KEY;' | psql disclosure-backend
	csvsql --doublequote --db postgresql:///disclosure-backend --insert inputs/oakland_referendums.csv
	echo 'ALTER TABLE "oakland_referendums" ADD COLUMN id SERIAL PRIMARY KEY;' | psql disclosure-backend
	csvsql --doublequote --db postgresql:///disclosure-backend --insert inputs/oakland_name_to_number.csv
	csvsql --doublequote --db postgresql:///disclosure-backend --insert inputs/oakland_committees.csv
	echo 'ALTER TABLE "oakland_committees" ADD COLUMN id SERIAL PRIMARY KEY;' | psql disclosure-backend
	echo 'CREATE TABLE "office_elections" (id SERIAL PRIMARY KEY, name VARCHAR(255));' | psql disclosure-backend
	echo 'CREATE TABLE "calculations" (id SERIAL PRIMARY KEY, subject_id integer, subject_type varchar(30), name varchar(40), value jsonb);' | psql disclosure-backend
	./make_view.sh
	./latest_only.sh efile_COAK_2016_496
	./latest_only.sh efile_COAK_2016_497
	./latest_only.sh efile_COAK_2016_A-Contributions
	./latest_only.sh efile_COAK_2016_B1-Loans
	./latest_only.sh efile_COAK_2016_B2-Loans
	./latest_only.sh efile_COAK_2016_C-Contributions
	./latest_only.sh efile_COAK_2016_D-Expenditure
	./latest_only.sh efile_COAK_2016_E-Expenditure
	./latest_only.sh efile_COAK_2016_F-Expenses
	./latest_only.sh efile_COAK_2016_F461P5-Expenditure
	./latest_only.sh efile_COAK_2016_F465P3-Expenditure
	./latest_only.sh efile_COAK_2016_F496P3-Contributions
	./latest_only.sh efile_COAK_2016_G-Expenditure
	./latest_only.sh efile_COAK_2016_H-Loans
	./latest_only.sh efile_COAK_2016_I-Contributions
	./latest_only.sh efile_COAK_2016_Summary
	./remove_duplicate_transactions.sh

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

inputs/oakland_name_to_number.csv:
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/1272oaLyQhKwQa6RicA5tBso6wFruum-mgrNm3O3VogI/pub?gid=896561174&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@

inputs/oakland_committees.csv:
	wget -q -O- \
		'https://docs.google.com/spreadsheets/d/1272oaLyQhKwQa6RicA5tBso6wFruum-mgrNm3O3VogI/pub?gid=1995437960&single=true&output=csv' | \
	sed -e '1s/ /_/g' | \
	sed -e '1s/[^a-zA-Z,_]//g' > $@
