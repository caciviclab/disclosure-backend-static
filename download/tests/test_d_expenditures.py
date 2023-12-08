from model.d_expenditures import DExpenditures

def test_d_expenditures_does_not_raise(transactions, filings, committees):
    ''' Just test that it doesn't error out '''
    d_expends = DExpenditures(
        transactions,
        filings,
        committees
    )

    df = d_expends.df

    assert df.shape[0] > 0
