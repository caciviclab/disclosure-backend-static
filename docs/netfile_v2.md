# Netfile API v2 Migration Plan

## Makefile changes to support new download

The Makefile will be updated to also download Netfile v2 files by running `python download/main.py` if the local environment is set up with credentials to access the files on Google Drive.

Two variables control whether the new Netfile v2 download and import will occur when `make download` and `make import` are run:
* NETFILE_V2_DOWNLOAD
* NETFILE_V2_IMPORT

The variables above will only be set if the `SERVICE_ACCOUNT_KEY_JSON` environment variable is set or a file exists at `.local/SERVICE_ACCOUNT_KEY_JSON.json` .  If the variables above aren't set at the top of the Makefile, the new downloads will not occur.  The two variables set targets that run during download and import.

The new download will download files to `.local/download`.

## Updating python package requirements

During development, a separate requirements.txt file was maintained in the `download` directory.  When we finally merge the code into main, this file will be deprecated. All required packages must be specified in the top level `requirements.txt` file that is used by the existing download code.  In other words, we have to make sure that the same versions of packages work for both the old and new download code.
