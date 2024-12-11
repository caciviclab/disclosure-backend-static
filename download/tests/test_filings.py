''' Test Filings model '''
import json
from pathlib import Path
import pytest
from model.filing import Filings

def test_filing_does_not_raise(filings_json):
    ''' Just test that it does not error '''
    Filings(filings_json)

def test_filing_pl_does_not_riase(filings_json):
    ''' Just test that .pl method does not error '''
    Filings(filings_json).pl
