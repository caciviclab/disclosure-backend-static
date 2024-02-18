FROM mcr.microsoft.com/vscode/devcontainers/python:3.9-bullseye

RUN curl -fsSL https://aka.ms/install-azd.sh | bash

ENV PYTHONUNBUFFERED 1

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends postgresql-client ruby-full

RUN pwd
COPY ./.devcontainer/post-create-command.sh /scripts/
COPY ./requirements.txt requirements.txt
COPY ./download/requirements.txt download/requirements.txt
COPY ./Gemfile Gemfile
COPY ./Gemfile.lock Gemfile.lock
RUN bash /scripts/post-create-command.sh

