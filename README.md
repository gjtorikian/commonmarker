# Qiita Marker

[![Build Status](https://github.com/increments/qiita-marker/actions/workflows/test.yml/badge.svg)](https://github.com/increments/qiita-marker/actions/workflows/test.yml) [![Gem Version](https://badge.fury.io/rb/qiita_marker.svg)](https://badge.fury.io/rb/qiita_marker)

:warning: This library is still in the testing phase. As such, development may be halted.

Qiita Marker is a Ruby library for Markdown processing, based on [CommonMarker](https://github.com/gjtorikian/commonmarker).
It will be a core module of [Qiita Markdown](https://github.com/increments/qiita-markdown) gem and not intended for direct use. If you are looking for Qiita-specified markdown processor, use [Qiita Markdown](https://github.com/increments/qiita-markdown) gem.

## Usage

Please see [CommonMarker's Usage](https://github.com/gjtorikian/commonmarker#usage).

In addition to CommonMarker's options and extensions, the following are available in Qiita Marker.

### Original options

#### Parse options

| Name | Description |
| --- | --- |
| `:MENTION_NO_EMPHASIS` | Prevent parsing mentions as emphasis. |
| `:AUTOLINK_CLASS_NAME` | Append `class="autolink"` to extension's autolinks. |

#### Render options

| Name | Description |
| --- | --- |
| `:CODE_DATA_METADATA` | Use `<code data-metadata>` for fenced code blocks. |
| `:MENTION_NO_EMPHASIS` | Prevent parsing mentions as emphasis. |
| `:AUTOLINK_CLASS_NAME` | Append `class="autolink"` to extension's autolinks. |

### Original extensions

- `:custom_block` - This provides support for customizable blocks.

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

### Versioning policy

Qiita Marker follows CommonMarker's updates by merging the upstream changes.
The version format is `MAJOR.MINOR.PATCH.FORK`. `MAJOR.MINOR.PATCH` is the same as the version of CommonMarker that Qiita Marker is based on. `FORK` is incremented on each release of Qiita Marker itself and reset to zero when any of `MAJOR.MINOR.PATCH` is bumped.

## License

Please see [LICENSE.txt](/LICENSE.txt).
