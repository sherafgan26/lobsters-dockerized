# syntax=docker/dockerfile:1.7
#
# Production image for Lobsters. Two stages:
#   1. builder  — installs gems + precompiles assets
#   2. runtime  — slim image, just what's needed to run Puma
#
# Build:  docker build -t lobsters:latest .

ARG RUBY_VERSION=4.0.0

FROM ruby:${RUBY_VERSION}-slim AS builder

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_FROZEN=1 \
    RAILS_ENV=production

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


FROM ruby:${RUBY_VERSION}-slim AS runtime

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_DEPLOYMENT=1 \
    RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
      libjemalloc2 \
      libvips \
      libmariadb3 \
      curl \
      tzdata \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

EXPOSE 3000

CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
