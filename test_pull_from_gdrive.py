import os
from gdrive_client.GDriveCopier import GDriveCopier

REPO_BRANCH = os.getenv('REPO_BRANCH','_LOCAL_')
GDRIVE_FOLDER = os.getenv('GDRIVE_FOLDER','netfile_redacted') or 'netfile_redacted'

downloads_dir = '.local/downloads'
os.makedirs(downloads_dir, exist_ok=True)
copier = GDriveCopier(GDRIVE_FOLDER, target_branch = REPO_BRANCH)
copier.download_to(downloads_dir)
print(f'Contents of downloads dir ({downloads_dir}):')
local_files = os.listdir(downloads_dir)
for local_file in local_files:
    print(local_file)
print('Done')
