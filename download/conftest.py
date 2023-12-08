''' Pytest config '''

pytest_plugins = [
    # Autoload all fixtures in every test because they are kept in a separate file from the tests themselves
    "tests.fixtures.data_fixtures"
]
