''' Test Filings model '''
from model.filing import Filings

def test_filing_does_not_raise(filings_json):
    ''' Just test that it does not error '''
    Filings(filings_json)

def test_filing_df_does_not_raise(filings_json):
    ''' Just test that .pl method does not error '''
    Filings(filings_json).df
