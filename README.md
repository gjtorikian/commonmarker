# Qiita Marker

[![Build Status](https://github.com/increments/qiita-marker/actions/workflows/test.yml/badge.svg)](https://github.com/increments/qiita-marker/actions/workflows/test.yml)

:warning: This library is still in the testing phase. As such, development may be halted.

Qiita Marker is a Ruby library for Markdown processing, based on [CommonMarker](https://github.com/gjtorikian/commonmarker).
It will be a core module of [Qiita Markdown](https://github.com/increments/qiita-markdown) gem and not intended for direct use. If you are looking for Qiita-specified markdown processor, use [Qiita Markdown](https://github.com/increments/qiita-markdown) gem.

## Usage

Please see [CommonMarker's Usage](https://github.com/gjtorikian/commonmarker#usage).

## Contributing

If you have suggestion or modification to this repository, please create an Issue or Pull Request.

### How to develop

```
# Clone repository
$ git clone git@github.com:increments/qiita_marker.git
$ cd qiita_marker

# Setup development environment
$ ./script/bootstrap

# Run test
$ bundle exec rake test
```

#### with Docker

```
# Clone repository
$ git clone git@github.com:increments/qiita_marker.git
$ cd qiita_marker

# Setup development environment
$ docker compose build
$ docker compose up -d
$ docker compose run --rm app ./script/bootstrap

# Run test
$ docker compose run --rm rake test
```

## License

Please see [LICENSE.txt](/LICENSE.txt).
