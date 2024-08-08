CREATE TABLE referendums (
	election_name VARCHAR(18) NOT NULL, 
	"Measure_number" VARCHAR(4) NOT NULL, 
	"Short_Title" VARCHAR(128) NOT NULL, 
	"Full_Title" VARCHAR(1024), 
	"Summary" VARCHAR(2048), 
	"VotersEdge" VARCHAR(129), 
	"Internal_notes" VARCHAR(1024), 
	data_warning VARCHAR(32), 
	is_approved BOOLEAN
);
