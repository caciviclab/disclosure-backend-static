'''
FPPC Form 460, Schedule D, Expenditures
'''
import polars as pl
from .schedule import ScheduleBase

class DExpenditures(ScheduleBase):
    '''
    Schedule D - Expenditures from FPPC Form 460
    '''
    def __init__(
        self,
        transactions: pl.DataFrame,
        filings: pl.DataFrame,
        committees: pl.DataFrame
    ):
        self._form_id = 'F460D'
        super().__init__(
            self._form_id,
            transactions,
            filings,
            committees
        )
