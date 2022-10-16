# CommonMarker

![Build Status](https://github.com/gjtorikian/commonmarker/workflows/CI/badge.svg) [![Gem Version](https://badge.fury.io/rb/commonmarker.svg)](http://badge.fury.io/rb/commonmarker)

Ruby wrapper for [libcmark-gfm](https://github.com/github/cmark),
GitHub's fork of the reference parser for CommonMark. It passes all of the C tests, and is therefore spec-complete. It also includes extensions to the CommonMark spec as documented in the [GitHub Flavored Markdown spec](http://github.github.com/gfm/), such as support for tables, strikethroughs, and autolinking.

For more information on available extensions, see [the documentation below](#extensions).

## Installation

Add this line to your application's Gemfile:

    gem 'commonmarker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install commonmarker

## Usage

### Converting to HTML

Call `render_html` on a string to convert it to HTML:

``` ruby
require 'commonmarker'
CommonMarker.to_html('Hi *there*', :DEFAULT)
# <p>Hi <em>there</em></p>\n
```

The second argument is optional--[see below](#options) for more information.

## Options

CommonMarker accepts the same options that CMark does, as symbols. Note that there is a distinction in CMark for "parse" options and "render" options, which are represented in the tables below.

### Parse options

| Name                          | Description
| ----------------------------- | -----------
| `:DEFAULT`                    | The default parsing system.
| `:SOURCEPOS`                  | Include source position in nodes
| `:UNSAFE`                     | Allow raw/custom HTML and unsafe links.
| `:VALIDATE_UTF8`              | Replace illegal sequences with the replacement character `U+FFFD`.
| `:SMART`                      | Use smart punctuation (curly quotes, etc.).
| `:LIBERAL_HTML_TAG`           | Support liberal parsing of inline HTML tags.
| `:FOOTNOTES`                  | Parse footnotes.
| `:STRIKETHROUGH_DOUBLE_TILDE` | Parse strikethroughs by double tildes (compatibility with [redcarpet](https://github.com/vmg/redcarpet))

### Render options

| Name                             | Description                                                     |
| ------------------               | -----------                                                     |
| `:DEFAULT`                       | The default rendering system.                                   |
| `:SOURCEPOS`                     | Include source position in rendered HTML.                       |
| `:HARDBREAKS`                    | Treat `\n` as hardbreaks (by adding `<br/>`).                   |
| `:UNSAFE`                        | Allow raw/custom HTML and unsafe links.                         |
| `:NOBREAKS`                      | Translate `\n` in the source to a single whitespace.            |
| `:VALIDATE_UTF8`                 | Replace illegal sequences with the replacement character `U+FFFD`. |
| `:SMART`                         | Use smart punctuation (curly quotes, etc.).                     |
| `:GITHUB_PRE_LANG`               | Use GitHub-style `<pre lang>` for fenced code blocks.           |
| `:LIBERAL_HTML_TAG`              | Support liberal parsing of inline HTML tags.                    |
| `:FOOTNOTES`                     | Render footnotes.                                               |
| `:STRIKETHROUGH_DOUBLE_TILDE`    | Parse strikethroughs by double tildes (compatibility with [redcarpet](https://github.com/vmg/redcarpet)) |
| `:TABLE_PREFER_STYLE_ATTRIBUTES` | Use `style` insted of `align` for table cells.                  |
| `:FULL_INFO_STRING`              | Include full info strings of code blocks in separate attribute. |

### Passing options

To apply an option, pass it as part of the hash:

``` ruby
CommonMarker.to_html("\"Hello,\" said the spider.", :SMART)
# <p>“Hello,” said the spider.</p>\n

CommonMarker.to_html("\"'Shelob' is my name.\"", [:HARDBREAKS, :SOURCEPOS])
```

For more information on these options, see [the comrak documentation](https://github.com/kivikakk/comrak#usage).

## Output formats

Commonmarker can only generate output in one format: HTML.

### HTML

```ruby
html = CommonMarker.to_html('*Hello* world!', :DEFAULT)
puts(html)

# <p><em>Hello</em> world!</p>
```

## Developing locally

After cloning the repo:

```
script/bootstrap
bundle exec rake compile
```

If there were no errors, you're done! Otherwise, make sure to follow the comrak dependency instructions.

## Benchmarks

Some rough benchmarks:

```
$ bundle exec rake benchmark

input size = 11064832 bytes

Warming up --------------------------------------
           redcarpet     2.000  i/100ms
commonmarker with to_html
                         1.000  i/100ms
            kramdown     1.000  i/100ms
Calculating -------------------------------------
           redcarpet     22.634  (± 4.4%) i/s -    114.000  in   5.054490s
commonmarker with to_html
                          7.340  (± 0.0%) i/s -     37.000  in   5.058352s
            kramdown      0.343  (± 0.0%) i/s -      2.000  in   5.834208s

Comparison:
           redcarpet:       22.6 i/s
commonmarker with to_html:        7.3 i/s - 3.08x  (± 0.00) slower
            kramdown:        0.3 i/s - 66.02x  (± 0.00) slower
```
