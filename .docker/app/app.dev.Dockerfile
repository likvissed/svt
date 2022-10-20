ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}-slim-buster

ARG BUNDLER_VERSION
ARG NODE_MAJOR
ARG YARN_VERSION
ARG RAILS_ROOT

ENV TZ=Asia/Krasnoyarsk
ENV LANG ru_RU.UTF-8
ENV LANGUAGE ru_RU:ru
ENV LC_ALL ru_RU.UTF-8

ENV DEBIAN_FRONTEND noninteractive

COPY .docker/etc/apt/sources.list /etc/apt/sources.list

# Common packages
RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    curl \
    less \
    git \
    locales \
    tzdata \
    netcat \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# Install bundler
RUN gem install bundler:${BUNDLER_VERSION}

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

# Install PHP
RUN apt-get update -qq && apt-get -yq dist-upgrade \
    php \
    php-cli \
    php-yaml \
    php-mysql \
    php-mbstring

# Set RU locale
RUN sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure locales && \
    update-locale LANG=ru_RU.UTF-8 && \
    locale-gen ru_RU.UTF-8 && \
    dpkg-reconfigure locales

# OpenSSL TLSv1.0
RUN sed -i 's,^\(MinProtocol[ ]*=\).*,\1'TLSv1.0',g' /etc/ssl/openssl.cnf && \
  sed -i 's,^\(CipherString[ ]*=\).*,\1'DEFAULT@SECLEVEL=1',g' /etc/ssl/openssl.cnf

# Set yarn proxy
RUN yarn config set proxy ${HTTP_PROXY} \
  && yarn config set https-proxy ${HTTP_PROXY}

# Create app folder
RUN mkdir -p ${RAILS_ROOT}
WORKDIR ${RAILS_ROOT}

STOPSIGNAL SIGTERM
