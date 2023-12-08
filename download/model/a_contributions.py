"""
Schedule A, Contributions
Hopefully this can be joined with other Schedule classes into a single Transaction class
"""
from .committee import Committees
from .filing import Filings
from .transaction import Transactions
from .schedule import ScheduleBase

class A_Contributions(ScheduleBase):
    """
    Each record represents Schedule A - Contributions from form 460
    """
    def __init__(
        self,
        transactions:Transactions,
        filings:Filings,
        committees:Committees
    ):
        self._form_id = 'F460A'
        super().__init__(
            self._form_id,
            transactions,
            filings,
            committees
        )
