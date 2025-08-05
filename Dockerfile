FROM ruby:3.4.4-slim-bookworm AS assets
LABEL maintainer="Nick Janetakis <nick.janetakis@gmail.com>"

WORKDIR /app

ARG UID=1000
ARG GID=1000

RUN bash -c "set -o pipefail && apt-get update \
  && apt-get install -y --no-install-recommends build-essential curl git libpq-dev libyaml-dev \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key -o /etc/apt/keyrings/nodesource.asc \
  && echo 'deb [signed-by=/etc/apt/keyrings/nodesource.asc] https://deb.nodesource.com/node_20.x nodistro main' | tee /etc/apt/sources.list.d/nodesource.list \
  && apt-get update && apt-get install -y --no-install-recommends nodejs \
  && corepack enable \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  && groupadd -g \"${GID}\" ruby \
  && useradd --create-home --no-log-init -u \"${UID}\" -g \"${GID}\" ruby \
  && mkdir /node_modules && chown ruby:ruby -R /node_modules /app"

USER ruby

# Configure git for bundle install and ensure git cache is available
RUN git config --global user.email "docker@example.com" && \
    git config --global user.name "Docker" && \
    git config --global --add safe.directory '*' && \
    mkdir -p ~/.bundle && \
    bundle config --global git.allow_insecure true

# Copy Gemfile and engines directory for local gem dependencies
COPY --chown=ruby:ruby Gemfile* ./
COPY --chown=ruby:ruby engines/ ./engines/
RUN bundle install --jobs 4 --retry 3 && \
    bundle cache --all

COPY --chown=ruby:ruby package.json *yarn* ./
RUN yarn install

ARG RAILS_ENV="development"
ARG NODE_ENV="development"
ENV RAILS_ENV="${RAILS_ENV}" \
    NODE_ENV="${NODE_ENV}" \
    PATH="${PATH}:/home/ruby/.local/bin:/node_modules/.bin" \
    USER="ruby"

COPY --chown=ruby:ruby . .

RUN if [ "${RAILS_ENV}" != "development" ]; then \
  SECRET_KEY_BASE_DUMMY=1 rails assets:precompile; fi

CMD ["zsh"]

###############################################################################

FROM ruby:3.4.4-slim-bookworm AS app
LABEL maintainer="Nick Janetakis <nick.janetakis@gmail.com>"

WORKDIR /app

ARG UID=1000
ARG GID=1000

ENV LANG="C.UTF-8"

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential curl libpq-dev libyaml-dev git zsh \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  && groupadd -g "${GID}" ruby \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" ruby \
  && chown ruby:ruby -R /app

USER ruby

# Configure git same as assets stage
RUN git config --global user.email "docker@example.com" && \
    git config --global user.name "Docker" && \
    git config --global --add safe.directory '*' && \
    mkdir -p ~/.bundle && \
    bundle config --global git.allow_insecure true

# Copy bundle config and cache from assets stage
COPY --chown=ruby:ruby --from=assets /usr/local/bundle /usr/local/bundle
COPY --chown=ruby:ruby --from=assets /home/ruby/.bundle /home/ruby/.bundle
COPY --chown=ruby:ruby --from=assets /home/ruby/.cache /home/ruby/.cache

COPY --chown=ruby:ruby bin/ ./bin
RUN chmod 0755 bin/*

ARG OMZ_VERSION=master
RUN BRANCH=${OMZ_VERSION} \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/${OMZ_VERSION}/tools/install.sh)" "" \
    --unattended

ARG RAILS_ENV="production"
ENV RAILS_ENV="${RAILS_ENV}" \
    PATH="${PATH}:/home/ruby/.local/bin" \
    USER="ruby"

COPY --chown=ruby:ruby --from=assets /app/public /public
COPY --chown=ruby:ruby . .

# Verify bundle installation
RUN bundle install --jobs 4 --retry 3

ENTRYPOINT ["/app/bin/docker-entrypoint-web"]

EXPOSE 8000

CMD ["rails", "s"]
