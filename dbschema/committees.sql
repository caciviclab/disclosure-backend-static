CREATE TABLE committees (
	"Ballot_Measure_Election" VARCHAR(18), 
	"Filer_ID" VARCHAR(32) NOT NULL, 
	"Filer_NamL" VARCHAR(173) NOT NULL, 
	"_Status" VARCHAR(19), 
	"_Committee_Type" VARCHAR(11), 
	"Ballot_Measure" VARCHAR(10), 
	"Support_Or_Oppose" VARCHAR(4), 
	candidate_controlled_id INTEGER, 
	"Start_Date" DATE, 
	"End_Date" DATE, 
	data_warning VARCHAR(84), 
	"Make_Active" BOOLEAN
);
