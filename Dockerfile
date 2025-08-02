FROM ruby:3.4.4-slim

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    git \
    curl && \
    rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN npm install -g yarn

# Set working directory
WORKDIR /app

# Copy Gemfiles
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN bundle config --global frozen 1 && \
    bundle install

# Copy package files
COPY package.json yarn.lock ./

# Install Node dependencies
RUN yarn install --frozen-lockfile

# Copy application code
COPY . .

# Precompile assets (for production)
# RUN bundle exec rails assets:precompile

# Create a non-root user
RUN groupadd -r app && useradd -r -g app app
RUN chown -R app:app /app
USER app

# Expose port
EXPOSE 3000

# Default command
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]