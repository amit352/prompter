# Dockerfile for Prompter gem
FROM ruby:3.2-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    git \
    bash \
    tzdata

# Set working directory
WORKDIR /app

# Copy gemspec and dependencies first for better caching
COPY prompter.gemspec Gemfile* /app/
COPY lib/prompter/version.rb /app/lib/prompter/

# Install gem dependencies
RUN bundle install

# Copy the entire gem
COPY . /app/

# Build and install the gem
RUN gem build prompter.gemspec && \
    gem install ./prompter-*.gem

# Create deployment directory
RUN mkdir -p /app/deployment

# Set deployment as working directory
WORKDIR /app/deployment

# Set default command
CMD ["prompter", "schema.yml", "output.yml"]
