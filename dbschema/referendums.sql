CREATE TABLE referendums (
	election_name VARCHAR(18) NOT NULL, 
	"Measure_number" VARCHAR(2) NOT NULL, 
	"Short_Title" VARCHAR(89) NOT NULL, 
	"Full_Title" VARCHAR(332), 
	"Summary" VARCHAR(1272), 
	"VotersEdge" VARCHAR(129), 
	"Internal_notes" VARCHAR(104), 
	data_warning VARCHAR(32), 
	is_approved BOOLEAN
);
