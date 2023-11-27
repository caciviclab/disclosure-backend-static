"""
Test that A_Contributions model is complete
"""
from pathlib import Path
from pprint import PrettyPrinter
import pandas as pd
from model.a_contributions import A_Contributions

def test_a_contributions_has_expected_fields(
    transactions_df,
    filings_df,
    committees_df
):
    """
    Test that A_Contributions has expect fields
    based on "\d A-Contributions" dumped from Postgres database disclosure-backend
    """
    a_contributions = A_Contributions(transactions_df, filings_df, committees_df).df

    expect_columns = pd.read_table(str(Path(__file__).parent / 'A-Contributions.schema.txt'),
        sep='|', header=1, skipinitialspace=True
    )
    expect_columns = expect_columns.rename(columns={
        expect_columns.columns[1]: 'column'
    })['column'].apply(lambda x: x.strip()).loc[1:].to_list()

    pp = PrettyPrinter()
    print('LEFT')
    pp.pprint(sorted(a_contributions.columns))
    print('RIGHT')
    pp.pprint(sorted(expect_columns))
    assert sorted(a_contributions.columns) == sorted(expect_columns)
