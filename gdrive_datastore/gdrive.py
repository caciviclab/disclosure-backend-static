import os
import json
from oauth2client.service_account import ServiceAccountCredentials
from pydrive2.auth import GoogleAuth 
from pydrive2.drive import GoogleDrive

import logging
logging.basicConfig(level=logging.INFO)

def test_data_pull(default_folder='', default_subfolder='_LOCAL_'):
    REPO_BRANCH = os.getenv('REPO_BRANCH',default_subfolder)
    GDRIVE_FOLDER = os.getenv('GDRIVE_FOLDER',default_folder) or default_folder

    downloads_dir = '.local/downloads'
    os.makedirs(downloads_dir, exist_ok=True)
    copier = GDriveCopier(GDRIVE_FOLDER, target_subfolder = REPO_BRANCH)
    copier.download_to(downloads_dir)
    logging.info(f'Contents of downloads dir ({downloads_dir}):')
    local_files = os.listdir(downloads_dir)
    for local_file in local_files:
        logging.info(local_file)
    logging.info('Done')


class GDriveCopier:
    '''This copier class supports uploading and downloading files between a local folder
and a folder on Google Drive.  

    The following has to be done to set up for uploading to and downloading from Google Drive:
        1. A service account has to be created in a project with access to the Google Drive API.
           It's probably best to create a GCP project specifically just for access to the 
           Google Drive API and create the service account in that project.  
        2. The directory on Google Drive has to be shared with the service account.  This is
           done by getting the e-mail of the service account and sharing with that e-mail 
           instead of a real person's e-mail.
        3. A private key (in JSON) has to be created for the service account.  The private key 
           should be placed in an environment variable, SERVICE_ACCOUNT_KEY_JSON.  For
           GitHub Actions, we can simply get the value from a secret of the same name.
    '''
    def __init__(self, target_folder, target_subfolder = ''):
        '''Initialize access to target location in Google Drive
         
        The target_subfolder value will force the target to be a sub-folder
        under target_folder that is named with the value in target_sub-folder.
        This ensures that we can upload to a different location when we run
        a workflow in a feature branch
        '''
        # set target
        self.target_folder = target_folder
        self.target_branch = target_subfolder
        # Establish connection with Google Drive
        gauth = GoogleAuth() 
        gauth.credentials = self.get_service_account_credentials()
        self.drive = GoogleDrive(gauth)
        # Locate folder on Google Drive
        logging.info(f'Checking for folder {self.target_folder}')
        self.folder_id = self.get_folder_id()
    
    def upload_from(self, local_folder):
        '''Upload files from local_folder to Google Drive'''
        # Get list of files in folder on Google Drive
        drive_files_dict = self.get_drive_files(self.folder_id)

        # Upload local files to folder on Google Drive
        local_files = os.listdir(local_folder)
        for local_file in local_files:
            logging.info(f'Uploading {local_file}')
            file_meta_data = {
                'parents': [{'id': self.folder_id}],
                'title':local_file
            }
            
            if local_file in drive_files_dict:
                # overwrite if file exists on Google Drive
                file_meta_data['id'] = drive_files_dict[local_file]['id']
            drive_file = self.drive.CreateFile(file_meta_data)
            drive_file.SetContentFile(f'{local_folder}/{local_file}')
            drive_file.Upload()

    def download_to(self, local_folder):
        '''Download files from Google Drive to local_folder'''
        #Get list of files in folder on Google Drive
        drive_files_dict = self.get_drive_files(self.folder_id)
        for file_name in drive_files_dict.keys():
            logging.info(f'Downloading {file_name}')
            drive_file = drive_files_dict[file_name]
            drive_file.GetContentFile(f'{local_folder}/{file_name}')

    def get_service_account_credentials(self):
        '''Extract service account credentials from service account JSON file with key'''
        scopes = ["https://www.googleapis.com/auth/drive"]
        key = self.get_private_key()
        key_dict = json.loads(key)
        credentials = ServiceAccountCredentials.from_json_keyfile_dict(key_dict, scopes=scopes)
        return credentials

    def get_private_key(self):
        '''Get the JSON string that has the private key for the service account.
        
        Look for it in the SERVICE_ACCOUNT_KEY_JSON environment variable and fall back
        to a JSON file in .local/SERVICE_ACCOUNT_KEY_JSON.json if the environment variable
        is empty or missing
        '''
        SERVICE_ACCOUNT_KEY_JSON = os.getenv('SERVICE_ACCOUNT_KEY_JSON','')
        if SERVICE_ACCOUNT_KEY_JSON == '':
            secret_file = os.path.join(os.path.join(os.getcwd(), '.local'),'SERVICE_ACCOUNT_KEY_JSON.json')
            with open(secret_file,'r') as f:
                SERVICE_ACCOUNT_KEY_JSON = f.read()
        return SERVICE_ACCOUNT_KEY_JSON

    def get_drive_files(self, folder_id):
        '''Get list of files in folder on Google Drive'''
        drive_files = self.drive.ListFile({'q':f"'{folder_id}' in parents and trashed=false"}).GetList()
        drive_files_dict = {}
        for drive_file in drive_files:
            drive_files_dict[drive_file['title']] = drive_file
        return drive_files_dict

    def get_folder_id(self):
        '''Get the folder id of the folder where files are uploaded'''
        folder_id = self.confirm_target_folder_exists()
        # if a target branch was specified, look for the sub-folder named after the branch
        # as the location where we expect to find uploaded files
        if self.target_branch != '':
            folder_id = self.ensure_branch_folder_exists(folder_id)

        return folder_id
    
    def confirm_target_folder_exists(self):
        '''Look in Google Drive for target_folder and return the id or raise an exception if it is missing'''
        file_list = self.drive.ListFile({'q': "trashed=false"}).GetList()
        folder_id = None
        for file in file_list: 
            if (file['title'] == self.target_folder) and (file['mimeType'] == 'application/vnd.google-apps.folder'):
                logging.info(f"title: {file['title']}, id: {file['id']}")
                folder_id = file['id']
        if folder_id is None:
            raise Exception(f'Missing folder {self.target_folder}.  Be sure to share the folder with the service account.')
        return folder_id
    
    def ensure_branch_folder_exists(self,parent_folder_id):
        '''Look in Google Drive for the branch sub-folder and return the id
        
        Create the folder if it is missing
        '''
        branch_files = self.get_drive_files(parent_folder_id)
        if self.target_branch in branch_files:
            folder_id = branch_files[self.target_branch]['id']
        else:
            drive_file = self.drive.CreateFile({'parents': [{'id': parent_folder_id}], 'title':self.target_branch, 'mimeType':'application/vnd.google-apps.folder'})
            drive_file.Upload()
            folder_id = drive_file['id']
        return folder_id
