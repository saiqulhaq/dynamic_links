FROM mcr.microsoft.com/devcontainers/ruby:3.2-bullseye

# Install PostgreSQL
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install postgresql postgresql-contrib libpq-dev \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install additional dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install build-essential git curl libssl-dev libreadline-dev \
    zlib1g-dev autoconf bison libyaml-dev libncurses5-dev libffi-dev libgdbm-dev \
    graphviz imagemagick nodejs npm sqlite3 redis-server \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN npm install -g yarn

# Set up PostgreSQL service
RUN mkdir -p /etc/service/postgresql
COPY ./start-postgresql.sh /etc/service/postgresql/run
RUN chmod +x /etc/service/postgresql/run

# Set up Redis service
RUN mkdir -p /etc/service/redis
COPY ./start-redis.sh /etc/service/redis/run
RUN chmod +x /etc/service/redis/run

# Switch to the vscode user
USER vscode

# Install commonly used Ruby gems
RUN gem install bundler solargraph rubocop ruby-debug-ide debase rdbg

# Set default Rails environment
ENV RAILS_ENV=development

WORKDIR /workspaces/dynamic_links

USER root
