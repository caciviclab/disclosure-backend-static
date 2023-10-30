""" Filings """
from .base import BaseModel

class Filings(BaseModel):
    """ A collection of filings """
    def __init__(self, filings):
        super().__init__([
            {
                'filing_nid': f['filingNid'],
                'filer_nid': f['filerMeta']['filerId'],
                'Report_Num': f['filingMeta']['amendmentSequence'],
                'Rpt_Date': f['filingMeta']['legalFilingDate'],
                'From_Date': f['filingMeta']['startDate'],
                'Thru_Date': f['filingMeta']['endDate'],
            } for f in filings
        ])

        self._dtypes = {
            'filing_nid': 'string',
            'filer_nid': int,
            'Report_Num': 'Int64',
            'Rpt_Date': 'string',
            'From_Date': 'string',
            'Thru_Date': 'string'
        }
