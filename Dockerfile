# Production image for Lobsters.
# Build:  docker build -t lobsters:latest .

ARG RUBY_VERSION=4.0.0

FROM ruby:${RUBY_VERSION}-slim

ENV BUNDLE_WITHOUT=development:test \
    RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
      build-essential \
      libjemalloc-dev \
      libvips-dev \
      libmariadb-dev \
      pkg-config \
      git \
      curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install --jobs 4 --retry 3

COPY . .

RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
