'''
FPPC Form 460, Schedule D, Expenditures
'''
import polars as pl
from .base import BaseModel

class D_Expenditures(BaseModel):
    def __init__(
        self,
        transactions: pl.DataFrame,
        filings: pl.DataFrame,
        committees: pl.DataFrame
    ):
        f460d_trans = transactions.filter(pl.col('cal_tran_type') == 'F460D')

        unique_committees = committees.group_by('Filer_ID').first()
