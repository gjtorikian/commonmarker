FROM ruby:2.7.2

RUN apt update \
  && apt install -y \
  clang-format \
  cmake \
  wget \
  && apt clean

# Install re2c
RUN wget https://github.com/skvadrik/re2c/releases/download/1.3/re2c-1.3.tar.xz \
  && tar xf re2c-1.3.tar.xz \
  && cd re2c-* \
  && ./configure \
  && make \
  && make install \
  && cd .. \
  && rm -rf re2c-*

WORKDIR /work

COPY . /work/

RUN script/bootstrap
