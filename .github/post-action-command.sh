#!/bin/bash

chmod a+x .devcontainer/post-create-command.sh
.devcontainer/post-create-command.sh

python test_pull_from_gdrive.py
