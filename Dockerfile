FROM ruby:2.7.2

ENV RE2C_VERSION 1.3

RUN apt update \
  && apt install -y \
  clang-format \
  cmake \
  wget \
  && apt clean

# Install re2c
RUN wget https://github.com/skvadrik/re2c/releases/download/${RE2C_VERSION}/re2c-${RE2C_VERSION}.tar.xz \
  && tar xf re2c-${RE2C_VERSION}.tar.xz \
  && cd re2c-${RE2C_VERSION} \
  && ./configure \
  && make \
  && make install \
  && cd .. \
  && rm -rf re2c-${RE2C_VERSION}

WORKDIR /work

COPY . /work/

RUN bundle config set clean 'true'
RUN bundle config set path 'vendor/gems'
