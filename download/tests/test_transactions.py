from model.transaction import DTYPES, Transactions

def test_transactions_does_not_raise(transactions_json):
    ''' Just check that it doesn't error '''
    Transactions(transactions_json)

def test_transactions_contains_expected_fields(transactions):
    ''' Check that Transactions has expected fields '''
    expect_cols = list(DTYPES.keys())

    actual_cols = transactions.df.columns

    assert sorted(actual_cols) == sorted(expect_cols)
