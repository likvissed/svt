ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}-slim-buster

ARG BUNDLER_VERSION
ARG NODE_MAJOR
ARG YARN_VERSION
ARG RAILS_ROOT
ARG RAILS_ENV

ENV TZ=Asia/Krasnoyarsk
ENV LANG ru_RU.UTF-8
ENV LANGUAGE ru_RU:ru
ENV LC_ALL ru_RU.UTF-8
ENV RAILS_ENV ${RAILS_ENV}
ENV NODE_ENV ${RAILS_ENV}

ENV DEBIAN_FRONTEND noninteractive

# Common packages
RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    curl \
    locales \
    tzdata \
    netcat \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# NodeJS
RUN curl -sL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash -

# Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list

# Install dependencies
RUN apt-get update -qq && apt-get -yq dist-upgrade \
  && apt-get install -yq --no-install-recommends \
    libpq-dev \
    default-libmysqlclient-dev \
    nodejs \
    yarn=${YARN_VERSION}-1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && truncate -s 0 /var/log/*log

# Set RU locale
RUN sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure locales && \
    update-locale LANG=ru_RU.UTF-8 && \
    locale-gen ru_RU.UTF-8 && \
    dpkg-reconfigure locales

# Install bundler
RUN gem install bundler:${BUNDLER_VERSION}
RUN echo 'gem: --no-rdoc --no-ri' > ~/.gemrc

# Set yarn proxy
RUN yarn config set proxy ${http_proxy} \
  && yarn config set https-proxy ${http_proxy}

# Create app folder
RUN mkdir -p ${RAILS_ROOT}
WORKDIR ${RAILS_ROOT}

# Install gems
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install --jobs 4 --without development test

# Install yarn packages
COPY package.json .
COPY yarn.lock .
RUN yarn install

COPY . .
RUN mkdir -p tmp/pids

STOPSIGNAL SIGTERM
