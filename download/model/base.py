""" This is the base model, upon all others shall be based """
import pandas as pd
import polars as pl

class BaseModel:
    """ Base model other models inherit from """
    def __init__(self, data):
        self._data = data
        self._df = None
        self._pl = None
        self._dtypes = []
        self._pl_dtypes = []
        self._sql_dtypes = []
        self._sql_cols = []
        self._sql_table_name = ''

    @property
    def data(self):
        """ Just return the data """
        return self._data
    
    @property
    def pl(self):
        ''' Return a Polars dataframe '''
        if not self._pl:
            self._pl = pl.DataFrame(self._data, schema=self._pl_dtypes)

        return self._pl
    
    @property
    def df(self):
        """ Get a dataframe of the data """
        if self._df is None or self._df.empty:
            self._df = pd.DataFrame(self._data).astype(self._dtypes)

        return self._df
    
    def to_sql(self, connection, **kwargs):
        """ Write to a postgresql table """
        options = {
            'index_label': 'id',
            'if_exists': 'replace'
        }
        options.update(kwargs)

        self.df[self._sql_cols].to_sql(
            self._sql_table_name,
            connection,
            dtype=self._sql_dtypes,
            **options
        )
