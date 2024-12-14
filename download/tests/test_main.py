from pathlib import Path
import main

def test_main_does_not_raise(monkeypatch):
    ''' Just check that it doesn't error out '''
    # Don't need to pull data, just use what's in test_data dir
    # but we could spy on pull_data to make sure it's called with expected args
    monkeypatch.setattr(main, 'pull_data', lambda subfolder='', default_folder='': None)

    test_data_dir = (Path(__file__).parent / 'test_data').resolve()

    monkeypatch.setattr(main, 'DATA_DIR_PATH', str(test_data_dir))

    test_output_dir = test_data_dir / 'output'
    test_output_dir.mkdir(exist_ok=True, parents=True)
    monkeypatch.setattr(main, 'OUTPUT_DIR', str(test_output_dir))

    main.main()
