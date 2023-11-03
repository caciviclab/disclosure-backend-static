"""
Schedule A, Contributions
Hopefully this can be joined with other Schedule classes into a single Transaction class
"""
import pandas as pd
#from sqlalchemy.types import BOOLEAN, DATE, DOUBLE_PRECISION, INTEGER, TIME, VARCHAR
from .base import BaseModel

class A_Contributions(BaseModel):
    """
    Each record represents Schedule A - Contributions from form 460
    """
    def __init__(
        self,
        transactions:pd.DataFrame,
        filings:pd.DataFrame,
        committees:pd.DataFrame
    ):
        f460a_trans = transactions.loc[transactions['cal_tran_type'] == 'F460A'].drop(
            columns=['cal_tran_type']
        )

        unique_committees = committees.groupby(['Filer_ID'], as_index=False).first()[
            ['filer_nid','Filer_ID','Filer_NamL','_Committee_Type']
        ]

        committee_filings = unique_committees.merge(filings, on='filer_nid', how='left').drop(
            columns=['filer_nid']
        ).rename(
            columns={
                'RptNum': 'Report_Num',
                '_Committee_Type': 'Committee_Type'
            }
        )

        committees_sans_filings = committee_filings[committee_filings['filing_nid'].isna()]

        f460a = committee_filings.merge(f460a_trans,
            how='inner',
            on='filing_nid'
        ).drop(
            columns=['filing_nid']
        )

        f460a[['Form_Type','tblCover_Offic_Dscr','tblCover_Office_Cd']] = ['00:00:00', '', '']

        super().__init__(f460a)

        self._dtypes = {
            'Filer_ID': 'string',
            'Filer_NamL': 'string',
            'Report_Num': 'Int64',
            'Committee_Type': 'string',
            'Rpt_Date': 'string',
            'From_Date': 'string',
            'Thru_Date': 'string',
            'Elect_Date': 'string',
            'tblCover_Office_Cd': 'string',
            'tblCover_Offic_Dscr': 'string',
            'Rec_Type': 'string',
            'Form_Type': 'string',
            'Tran_ID': 'string',
            'Entity_Cd': 'string',
            'Tran_NamL': 'string',
            'Tran_NamF': 'string',
            'Tran_NamT': 'string',
            'Tran_NamS': 'string',
            'Tran_Adr1': 'string',
            'Tran_Adr2': 'string',
            'Tran_City': 'string',
            'Tran_State': 'string',
            'Tran_Zip4': 'string',
            'Tran_Emp': 'string',
            'Tran_Occ': 'string',
            'Tran_Self': bool,
            'Tran_Type': 'string',
            'Tran_Date': 'string',
            'Tran_Date1': 'string',
            'Tran_Amt1': float,
            'Tran_Amt2': float,
            'Tran_Dscr': 'string',
            'Cmte_ID': 'string',
            'Tres_NamL': 'string',
            'Tres_NamF': 'string',
            'Tres_NamT': 'string',
            'Tres_NamS': 'string',
            'Tres_Adr1': 'string',
            'Tres_Adr2': 'string',
            'Tres_City': 'string',
            'Tres_State': 'string',
            'Tres_Zip': 'string',
            'Intr_NamL': 'string',
            'Intr_NamF': 'string',
            'Intr_NamT': 'string',
            'Intr_NamS': 'string',
            'Intr_Adr1': 'string',
            'Intr_Adr2': 'string',
            'Intr_City': 'string',
            'Intr_State': 'string',
            'Intr_Zip4': 'string',
            'Intr_Emp': 'string',
            'Intr_Occ': 'string',
            'Intr_Self': bool,
            'Cand_NamL': 'string',
            'Cand_NamF': 'string',
            'Cand_NamT': 'string',
            'Cand_NamS': 'string',
            'tblDetlTran_Office_Cd': 'string',
            'tblDetlTran_Offic_Dscr': 'string',
            'Juris_Cd': 'string',
            'Juris_Dscr': 'string',
            'Dist_No': 'string',
            'Off_S_H_Cd': 'string',
            'Bal_Name': 'string',
            'Bal_Num': 'string',
            'Bal_Juris': 'string',
            'Sup_Opp_Cd': 'string',
            'Memo_Code': 'string',
            'Memo_RefNo': 'string',
            'BakRef_TID': 'string',
            'XRef_SchNm': 'string',
            'XRef_Match': 'string',
            'Loan_Rate': 'string',
            'Int_CmteId': 'Int64'
        }
        #self._sql_dtypes = {
        #    'Filer_ID': VARCHAR(9),
        #    'Filer_NamL': VARCHAR(183),
        #    'Report_Num': INTEGER,
        #    'Committee_Type': VARCHAR(64),
        #    'Rpt_Date': DATE,
        #    'From_Date': DATE,
        #    'Thru_Date': DATE,
        #    'Elect_Date': DATE,
        #    'tblCover_Office_Cd': VARCHAR(64),
        #    'tblCover_Offic_Dscr': VARCHAR(64),
        #    'Rec_Type': VARCHAR(4),
        #    'Form_Type': TIME,
        #    'Tran_ID': VARCHAR(12),
        #    'Entity_Cd': VARCHAR(3),
        #    'Tran_NamL': VARCHAR(199),
        #    'Tran_NamF': VARCHAR(38),
        #    'Tran_NamT': VARCHAR(6),
        #    'Tran_NamS': VARCHAR(5),
        #    'Tran_Adr1': VARCHAR(64),
        #    'Tran_Adr2': VARCHAR(64),
        #    'Tran_City': VARCHAR(50),
        #    'Tran_State': VARCHAR(4),
        #    'Tran_Zip4': VARCHAR(10),
        #    'Tran_Emp': VARCHAR(92),
        #    'Tran_Occ': VARCHAR(60),
        #    'Tran_Self': BOOLEAN,
        #    'Tran_Type': VARCHAR(4),
        #    'Tran_Date': DATE,
        #    'Tran_Date1': DATE,
        #    'Tran_Amt1': DOUBLE_PRECISION,
        #    'Tran_Amt2': DOUBLE_PRECISION,
        #    'Tran_Dscr': VARCHAR(56),
        #    'Cmte_ID': VARCHAR(9),
        #    'Tres_NamL': VARCHAR(4),
        #    'Tres_NamF': VARCHAR(4),
        #    'Tres_NamT': VARCHAR(64),
        #    'Tres_NamS': VARCHAR(64),
        #    'Tres_Adr1': VARCHAR(64),
        #    'Tres_Adr2': VARCHAR(64),
        #    'Tres_City': VARCHAR(7),
        #    'Tres_State': VARCHAR(4),
        #    'Tres_Zip': INTEGER,
        #    'Intr_NamL': VARCHAR(74),
        #    'Intr_NamF': VARCHAR(6),
        #    'Intr_NamT': VARCHAR(64),
        #    'Intr_NamS': VARCHAR(64),
        #    'Intr_Adr1': VARCHAR(64),
        #    'Intr_Adr2': VARCHAR(64),
        #    'Intr_City': VARCHAR(13),
        #    'Intr_State': VARCHAR(4),
        #    'Intr_Zip4': VARCHAR(10),
        #    'Intr_Emp': VARCHAR(15),
        #    'Intr_Occ': VARCHAR(8),
        #    'Intr_Self': BOOLEAN,
        #    'Cand_NamL': VARCHAR(64),
        #    'Cand_NamF': VARCHAR(64),
        #    'Cand_NamT': VARCHAR(64),
        #    'Cand_NamS': VARCHAR(64),
        #    'tblDetlTran_Office_Cd': VARCHAR(4),
        #    'tblDetlTran_Offic_Dscr': VARCHAR(19),
        #    'Juris_Cd': VARCHAR(4),
        #    'Juris_Dscr': VARCHAR(64),
        #    'Dist_No': VARCHAR(64),
        #    'Off_S_H_Cd': VARCHAR(64),
        #    'Bal_Name': VARCHAR(64),
        #    'Bal_Num': VARCHAR(4),
        #    'Bal_Juris': VARCHAR(64),
        #    'Sup_Opp_Cd': VARCHAR(64),
        #    'Memo_Code': VARCHAR(64),
        #    'Memo_RefNo': VARCHAR(11),
        #    'BakRef_TID': VARCHAR(64),
        #    'XRef_SchNm': VARCHAR(64),
        #    'XRef_Match': VARCHAR(64),
        #    'Loan_Rate': VARCHAR(64),
        #    'Int_CmteId': INTEGER
        #}
        #self._sql_cols = list(self._sql_dtypes.keys())
        self._sql_table_name = 'A-Contributions'
