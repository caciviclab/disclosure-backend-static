#!/bin/bash
set -euo pipefail

deploy() {
  git add build
  git config --global user.name 'Tom Dooner'
  git config --global user.email 'tomdooner@gmail.com'
  git commit -m 'Run `make clean import process`'"\n\n[skip ci]"
  git push --force \
    "https://$GITHUB_AUTH_TOKEN@github.com/caciviclab/disclosure-backend-static.git" \
    HEAD:test_auto_updating \
    | sed -e "s/$GITHUB_AUTH_TOKEN//"
}

if [ "${TRAVIS_EVENT_TYPE}" = "cron" -o "${TRAVIS_BRANCH}" = "automatic_updating" ]; then
  set -x
  deploy
else
  echo "Not deploying since this is not a cron job or on the 'automatic_updating' branch."
fi
