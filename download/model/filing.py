""" Filings """
from polars import UInt64, Utf8
from .base import BaseModel

class Filings(BaseModel):
    """ A collection of filings """
    def __init__(self, filings):
        super().__init__([
            {
                'filing_nid': f['filingNid'], # filingNid is an UUID, with dashes, like 4f6949c8-3765-484e-8e74-050559c077c5
                'filer_nid': int(f['filerMeta']['filerId']), # filerId is an int
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

        self._pl_dtypes = {
            'filing_nid': Utf8,
            'filer_nid': UInt64,
            'Report_Num': UInt64,
            'Rpt_Date': Utf8,
            'From_Date': Utf8,
            'Thru_Date': Utf8

        }
