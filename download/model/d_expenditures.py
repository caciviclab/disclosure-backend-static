'''
FPPC Form 460, Schedule D, Expenditures
'''
from .committee import Committees
from .filing import Filings
from .transaction import Transactions
from .schedule import ScheduleBase

class DExpenditures(ScheduleBase):
    '''
    Schedule D - Expenditures from FPPC Form 460
    '''
    def __init__(
        self,
        transactions:Transactions,
        filings:Filings,
        committees:Committees
    ):
        self._form_id = 'F460D'
        super().__init__(
            self._form_id,
            transactions,
            filings,
            committees
        )
