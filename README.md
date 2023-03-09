# Commonmarker

> **Note**
> This README refers to the behavior in the new 1.0.0.pre gem.

Ruby wrapper for Rust's [comrak](https://github.com/kivikakk/comrak) crate.

It passes all of the CommonMark test suite, and is therefore spec-complete. It also includes extensions to the CommonMark spec as documented in the [GitHub Flavored Markdown spec](http://github.github.com/gfm/), such as support for tables, strikethroughs, and autolinking.

For more information on available extensions, see [the documentation below](#extension-options).

## Installation

Add this line to your application's Gemfile:

    gem 'commonmarker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install commonmarker

## Usage

### Converting to HTML

Call `to_html` on a string to convert it to HTML:

```ruby
require 'commonmarker'
Commonmarker.to_html('"Hi *there*"', options: {
    parse: { smart: true }
})
# <p>“Hi <em>there</em>”</p>\n
```

The second argument is optional--[see below](#options) for more information.

## Options and plugins

### Options

Commonmarker accepts the same parse, render, and extensions options that comrak does, as a hash dictionary with symbol keys:

```ruby
Commonmarker.to_html('"Hi *there*"', options:{
  parse: { smart: true },
  render: { hardbreaks: false}
})
```

Note that there is a distinction in comrak for "parse" options and "render" options, which are represented in the tables below.

### Parse options

| Name                  | Description                                                                          | Default |
| --------------------- | ------------------------------------------------------------------------------------ | ------- |
| `smart`               | Punctuation (quotes, full-stops and hyphens) are converted into 'smart' punctuation. | `false` |
| `default_info_string` | The default info string for fenced code blocks.                                      | `""`    |

### Render options

| Name              | Description                                                                                            | Default |
| ----------------- | ------------------------------------------------------------------------------------------------------ | ------- |
| `hardbreaks`      | [Soft line breaks](http://spec.commonmark.org/0.27/#soft-line-breaks) translate into hard line breaks. | `true`  |
| `github_pre_lang` | GitHub-style `<pre lang="xyz">` is used for fenced code blocks with info tags.                         | `true`  |
| `width`           | The wrap column when outputting CommonMark.                                                            | `80`    |
| `unsafe`          | Allow rendering of raw HTML and potentially dangerous links.                                           | `false` |
| `escape`          | Escape raw HTML instead of clobbering it.                                                              | `false` |

As well, there are several extensions which you can toggle in the same manner:

```ruby
Commonmarker.to_html('"Hi *there*"', options: {
    extension: { footnotes: true, description_lists: true },
    render: { hardbreaks: false}
})
```

### Extension options

| Name                     | Description                                                                                                         | Default |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------- | ------- |
| `strikethrough`          | Enables the [strikethrough extension](https://github.github.com/gfm/#strikethrough-extension-) from the GFM spec.   | `true`  |
| `tagfilter`              | Enables the [tagfilter extension](https://github.github.com/gfm/#disallowed-raw-html-extension-) from the GFM spec. | `true`  |
| `table`                  | Enables the [table extension](https://github.github.com/gfm/#tables-extension-) from the GFM spec.                  | `true`  |
| `autolink`               | Enables the [autolink extension](https://github.github.com/gfm/#autolinks-extension-) from the GFM spec.            | `true`  |
| `tasklist`               | Enables the [task list extension](https://github.github.com/gfm/#task-list-items-extension-) from the GFM spec.     | `true`  |
| `superscript`            | Enables the superscript Comrak extension.                                                                           | `false` |
| `header_ids`             | Enables the header IDs Comrak extension. from the GFM spec.                                                         | `""`    |
| `footnotes`              | Enables the footnotes extension per `cmark-gfm`.                                                                    | `false` |
| `description_lists`      | Enables the description lists extension.                                                                            | `false` |
| `front_matter_delimiter` | Enables the front matter extension.                                                                                 | `""`    |
| `shortcodes`             | Enables the shortcodes extension.                                                                                   | `true`  |

For more information on these options, see [the comrak documentation](https://github.com/kivikakk/comrak#usage).

### Plugins

In addition to the possibilities provided by generic CommonMark rendering, Commonmarker also supports plugins as a means of
providing further niceties.

#### Syntax Highlighter Plugin

````ruby
code = <<~CODE
  ```ruby
  def hello
  puts "hello"
  end
CODE

puts Commonmarker.to_html(code, plugins: { syntax_highlighter: { theme: "InspiredGitHub" } })

# <pre style="background-color:#ffffff;" lang="ruby"><code>
# <span style="font-weight:bold;color:#a71d5d;">def </span><span style="font-weight:bold;color:#795da3;">hello
# </span><span style="color:#62a35c;">puts </span><span style="color:#183691;">&quot;hello&quot;
# </span><span style="font-weight:bold;color:#a71d5d;">end
# </span>
# </code></pre>
````

To disable this plugin, pass `nil`:

```ruby
Commonmarker.to_html(code, plugins: { syntax_highlighter: nil })
# or
Commonmarker.to_html(code, plugins: { syntax_highlighter: { theme: nil } })
```

You can also provide a `path` to a directory containing `.tmtheme` files to load:

```ruby

Commonmarker.to_html(code, plugins: { syntax_highlighter: { theme: "Monokai", path: "./themes" } })
```

##### Available themes

Here's [a list of themes available by default](https://docs.rs/syntect/5.0.0/syntect/highlighting/struct.ThemeSet.html#implementations):

- `"base16-ocean.dark"`
- `"base16-eighties.dark"`
- `"base16-mocha.dark"`
- `"base16-ocean.light"`
- `"InspiredGitHub"`
- `"Solarized (dark)"`
- `"Solarized (light)"`

## Output formats

Commonmarker can currently only generate output in one format: HTML.

### HTML

```ruby
puts Commonmarker.to_html('*Hello* world!')

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
           redcarpet     22.317  (± 4.5%) i/s -    112.000  in   5.036374s
commonmarker with to_html
                          5.815  (± 0.0%) i/s -     30.000  in   5.168869s
            kramdown      0.327  (± 0.0%) i/s -      2.000  in   6.121486s

Comparison:
           redcarpet:       22.3 i/s
commonmarker with to_html:        5.8 i/s - 3.84x  (± 0.00) slower
            kramdown:        0.3 i/s - 68.30x  (± 0.00) slower
```
