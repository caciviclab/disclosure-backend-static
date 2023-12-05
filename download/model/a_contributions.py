"""
Schedule A, Contributions
Hopefully this can be joined with other Schedule classes into a single Transaction class
"""
import polars as pl
from .schedule import ScheduleBase

class A_Contributions(ScheduleBase):
    """
    Each record represents Schedule A - Contributions from form 460
    """
    def __init__(
        self,
        transactions:pl.DataFrame,
        filings:pl.DataFrame,
        committees:pl.DataFrame
    ):
        self._form_id = 'F460A'
        super().__init__(
            self._form_id,
            transactions,
            filings,
            committees
        )
