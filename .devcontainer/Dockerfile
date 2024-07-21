#FROM mcr.microsoft.com/vscode/devcontainers/python:3.9-bullseye
FROM mcr.microsoft.com/vscode/devcontainers/python:3.9-bookworm

RUN curl -fsSL https://aka.ms/install-azd.sh | bash

ENV PYTHONUNBUFFERED 1

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends postgresql-client ruby-full

# install rvm
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import -
RUN curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN usermod -a -G rvm vscode
# for now, we can switch to ruby 2.7.1 by running .devcontainer/install-ruby-2.7.1.sh


COPY ./.devcontainer/post-create-command.sh /scripts/
COPY ./requirements.txt requirements.txt
COPY ./Gemfile Gemfile
COPY ./Gemfile.lock Gemfile.lock
RUN bash /scripts/post-create-command.sh

