'''
Abstracts much of the boilerplate common to FPPC Form 460 Schedule data
'''
import polars as pl

DTYPES = {
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

class ScheduleBase:
    '''
    Sets common schema for Form 460 Schedule data
    '''
    def __init__(
        self,
        form_id: str,
        transactions: pl.DataFrame,
        filings: pl.DataFrame,
        committees: pl.DataFrame
    ):
        schedule = committees.lazy().group_by('Filer_ID').first().join(
            filings.lazy(),
            on='filer_nid',
            how='inner'
        ).rename({
            '_Committee_Type': 'Committee_Type'
        }).join(
            transactions.lazy().filter(pl.col('cal_tran_type') == form_id),
            on='filing_nid',
            how='inner'
        ).drop([ 'filing_nid' ])

        self._lazy = schedule

        self._dtypes = DTYPES

    @property
    def lazy(self):
        return self._lazy

    @property
    def df(self):
        # QUESTION: Does this invalidate self._lazy?
        return self._lazy.collect()
