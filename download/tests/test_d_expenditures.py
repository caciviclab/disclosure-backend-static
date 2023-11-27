from model.d_expenditures import DExpenditures

def test_d_expenditures_does_not_raise(transactions_df, filings_df, committees_df):
    ''' Just test that it doesn't error out '''
    d_expends = DExpenditures(
        transactions_df,
        filings_df,
        committees_df
    )

    df = d_expends.df

    assert df.shape[0] > 0
