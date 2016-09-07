# Disclosure Backend Static

I'm not proud of this, but we're gunning toward a deadline and I want to be
able to quickly iterate on the backend. That means it needs to be 1) fast to
run, 2) written with a programming language I know, and 3) as conceptually
simple as possible.

Our existing `disclosure-backend` project is none of the three.

This project implements a basic ETL pipeline to download the Oakland netfile
data, download the CSV human-curated data for Oakland, and combine the two. The
output is a directory of JSON files which mimic the existing API structure so
no client code changes will be required.

## Installation

```bash
brew install gnumeric postgresql
sudo pip install csvkit psycopg2
gem install pg bundler
bundle install
```

## Running

```bash
make import    # <- only need to run the first time
make process
# everything is output into the "build" folder
```

## Deploying
This is hosted on Tom's personal server, accessible with an API root of

http://disclosure-backend-static.f.tdooner.com

(e.g. http://disclosure-backend-static.f.tdooner.com/office_election/35)

This means that unfortuately, only I can deploy it right now.
