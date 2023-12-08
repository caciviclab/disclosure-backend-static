""" This is the base model, upon all others shall be based """
import polars as pl

class BaseModel:
    """ Base model other models inherit from """
    def __init__(self, data):
        self._data = data
        self._df = None
        self._lazy = None
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
    def lazy(self):
        ''' Return a Polars Lazyframe '''
        if self._lazy is None:
            self._lazy = pl.LazyFrame(self._data, schema=self._dtypes)

        return self._lazy

    @property
    def df(self):
        ''' Return a Polars dataframe '''
        if self._df is None:
            self._df = self.lazy.collect()

        return self._df
    
