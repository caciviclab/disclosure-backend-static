CREATE TABLE "E-Expenditure" (
	"Filer_ID" VARCHAR(9) NOT NULL, 
	"Filer_NamL" VARCHAR(183) NOT NULL, 
	"Report_Num" VARCHAR(3) NOT NULL, 
	"Committee_Type" VARCHAR(3) NOT NULL, 
	"Rpt_Date" DATE NOT NULL, 
	"From_Date" DATE NOT NULL, 
	"Thru_Date" DATE NOT NULL, 
	"Elect_Date" DATE, 
	"tblCover_Office_Cd" VARCHAR(32), 
	"tblCover_Offic_Dscr" VARCHAR(32), 
	"Rec_Type" VARCHAR(4) NOT NULL, 
	"Form_Type" VARCHAR(1) NOT NULL, 
	"Tran_ID" VARCHAR(12) NOT NULL, 
	"Entity_Cd" VARCHAR(4), 
	"Payee_NamL" VARCHAR(127), 
	"Payee_NamF" VARCHAR(41), 
	"Payee_NamT" VARCHAR(4), 
	"Payee_NamS" VARCHAR(4), 
	"Payee_Adr1" VARCHAR(32), 
	"Payee_Adr2" VARCHAR(32), 
	"Payee_City" VARCHAR(27), 
	"Payee_State" VARCHAR(4), 
	"Payee_Zip4" VARCHAR(10), 
	"Expn_Date" DATE, 
	"Amount" FLOAT NOT NULL, 
	"Cum_YTD" FLOAT, 
	"Expn_ChkNo" VARCHAR(12), 
	"Expn_Code" VARCHAR(4), 
	"Expn_Dscr" VARCHAR(174), 
	"Agent_NamL" VARCHAR(32), 
	"Agent_NamF" VARCHAR(32), 
	"Agent_NamT" VARCHAR(32), 
	"Agent_NamS" VARCHAR(32), 
	"Cmte_ID" VARCHAR(9), 
	"Tres_NamL" VARCHAR(19), 
	"Tres_NamF" VARCHAR(6), 
	"Tres_NamT" VARCHAR(32), 
	"Tres_NamS" VARCHAR(32), 
	"Tres_Adr1" VARCHAR(32), 
	"Tres_Adr2" VARCHAR(32), 
	"Tres_City" VARCHAR(7), 
	"Tres_ST" VARCHAR(4), 
	"Tres_ZIP4" INTEGER, 
	"Cand_NamL" VARCHAR(19), 
	"Cand_NamF" VARCHAR(17), 
	"Cand_NamT" VARCHAR(4), 
	"Cand_NamS" VARCHAR(32), 
	"Office_Cd" VARCHAR(4), 
	"Offic_Dscr" VARCHAR(40), 
	"Juris_Cd" VARCHAR(4), 
	"Juris_Dscr" VARCHAR(31), 
	"Dist_No" INTEGER, 
	"Off_S_H_Cd" VARCHAR(32), 
	"Bal_Name" VARCHAR(188), 
	"Bal_Num" VARCHAR(4), 
	"Bal_Juris" VARCHAR(31), 
	"Sup_Opp_Cd" VARCHAR(4), 
	"Memo_Code" VARCHAR(32), 
	"Memo_RefNo" VARCHAR(8), 
	"BakRef_TID" VARCHAR(11), 
	"G_From_E_F" VARCHAR(32), 
	"XRef_SchNm" VARCHAR(32), 
	"XRef_Match" VARCHAR(4)
);