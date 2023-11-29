"""
Schedule A, Contributions
Hopefully this can be joined with other Schedule classes into a single Transaction class
"""
from .schedule import ScheduleBase

class A_Contributions(ScheduleBase):
    """
    Each record represents Schedule A - Contributions from form 460
    """
    def __init__(
        self,
        transactions:pd.DataFrame,
        filings:pd.DataFrame,
        committees:pd.DataFrame
    ):
        self._form_id = 'F460A'
        super().__init__(
            self._form_id,
            transactions,
            filings,
            committees
        )
