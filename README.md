# Commonmarker

Ruby wrapper for Rust's [comrak](https://github.com/kivikakk/comrak) crate.

It passes all of the CommonMark test suite, and is therefore spec-complete. It also includes extensions to the CommonMark spec as documented in the [GitHub Flavored Markdown spec](http://github.github.com/gfm/), such as support for tables, strikethroughs, and autolinking.

> [!NOTE]
> By default, the following extensions are enabled for end user convenience: `strikethrough`, `table`, `autolink`, `tasklist` (all from the [GFM spec](http://github.github.com/gfm/)), and `shortcodes`. The `syntax_highlighter` plugin is also enabled by default, using the `"base16-ocean.dark"` theme.
>
> For more information on the available options and extensions, see [the documentation below](#options-and-plugins).

## Installation

Add this line to your application's Gemfile:

    gem 'commonmarker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install commonmarker

## Usage

This gem expects to receive UTF-8 strings. Ensure your strings are the right encoding before passing them into `Commonmarker`.

### Converting to HTML

Call `to_html` on a string to convert it to HTML:

```ruby
require 'commonmarker'
Commonmarker.to_html('"Hi *there*"', options: {
    parse: { smart: true }
})
# => <p>“Hi <em>there</em>”</p>\n
```

(The second argument is optional--[see below](#options-and-plugins) for more information.)

### Reusing a configuration

`Commonmarker.to_html` and `Commonmarker.parse` process their `options` and `plugins` on every call. When you convert many documents with the same settings, build a `Commonmarker` instance once and call `to_html` or `parse` on it instead:

```ruby
require 'commonmarker'

markdown = Commonmarker.new(options: { parse: { smart: true } }, plugins: { syntax_highlighter: { theme: "InspiredGitHub" } })

markdown.to_html('"Hi *there*"')
# => <p>“Hi <em>there</em>”</p>\n

doc = markdown.parse("*Hello* world")
doc.to_html
# => <p><em>Hello</em> world</p>\n
```

The options and plugins are validated and processed when the instance is created, so invalid values raise from `Commonmarker.new` rather than from the first conversion, and changing the hashes afterwards has no effect on the instance. Instances hold no mutable state, so one can live in a constant and be shared across threads. `Commonmarker.to_html(text, options: o, plugins: p)` is the same as `Commonmarker.new(options: o, plugins: p).to_html(text)`.

`to_html` and `to_commonmark` also accept a `Commonmarker::Node`, so a document you parsed and then modified renders with the same settings without passing them again:

```ruby
doc = markdown.parse("*Hello* [GitHub](https://www.github.com)")

# Transform links to regular text
doc.walk do |node|
  node.replace(node.first_child) if node.type == :link
end

markdown.to_html(doc)
# => <p><em>Hello</em> GitHub</p>\n
markdown.to_commonmark(doc)
# => *Hello* GitHub\n
```

`Node#to_html` and `Node#to_commonmark` keep their own `options:` and `plugins:` arguments for one-off renders.

### Generating a document

You can also parse a string to receive a `:document` node. You can then print that node to HTML, iterate over the children, and do other fun node stuff. For example:

```ruby
require 'commonmarker'

doc = Commonmarker.parse("*Hello* world", options: {
    parse: { smart: true }
})
puts(doc.to_html) # => <p><em>Hello</em> world</p>\n

doc.walk do |node|
  puts node.type # => [:document, :paragraph, :emph, :text, :text]
end
```

(The second argument is optional--[see below](#options-and-plugins) for more information.)

When it comes to modifying the document, you can perform the following operations:

- `insert_before`
- `insert_after`
- `prepend_child`
- `append_child`
- `delete`

You can also get the source position of a node by calling `source_position`:

```ruby
doc = Commonmarker.parse("*Hello* world")
puts doc.first_child.first_child.source_position
# => {:start_line=>1, :start_column=>1, :end_line=>1, :end_column=>7}
```

You can also modify the following attributes:

- `url`
- `title`
- `header_level`
- `list_type`
- `list_start`
- `list_tight`
- `fence_info`
- `alert_type`

#### Example: Walking the AST

You can use `walk` or `each` to iterate over nodes:

- `walk` will iterate on a node and recursively iterate on a node's children.
- `each` will iterate on a node's direct children, but no further.

```ruby
require 'commonmarker'

# parse some string
doc = Commonmarker.parse("# The site\n\n [GitHub](https://www.github.com)")

# Walk tree and print out URLs for links
doc.walk do |node|
  if node.type == :link
    printf("URL = %s\n", node.url)
  end
end
# => URL = https://www.github.com

# Transform links to regular text
doc.walk do |node|
  if node.type == :link
    node.insert_before(node.first_child)
    node.delete
  end
end
# => <h1><a href=\"#the-site\"></a>The site</h1>\n<p>GitHub</p>\n
```

#### Example: Converting a document back into raw CommonMark

You can use `to_commonmark` on a node to render it as raw text:

```ruby
require 'commonmarker'

# parse some string
doc = Commonmarker.parse("# The site\n\n [GitHub](https://www.github.com)")

# Transform links to regular text
doc.walk do |node|
  if node.type == :link
    node.insert_before(node.first_child)
    node.delete
  end
end

doc.to_commonmark
# => # The site\n\nGitHub\n
```

### Reading and writing node content

`string_content` reads and writes the text of nodes whose content is plain text (like `:text`, `:code`, and `:code_block`).

`literal` reads and writes the raw string a node carries, for every node type that has one (like `:text`, `:code`, `:code_block`, `:html_block`, `:html_inline`, `:raw`, `:math`, and `:frontmatter`).

The two exist separately because they mean different things. Rewriting `string_content` only ever swaps text for text. Rewriting `literal` on an `:html_block`, `:html_inline`, or `:raw` node writes markup that is emitted unescaped:

```ruby
doc = Commonmarker.parse("A <b>bold</b> claim")

doc.walk do |node|
  node.literal = "<i>" if node.type == :html_inline && node.literal == "<b>"
end
```

Note that a `:frontmatter` node's literal includes its delimiters and trailing newlines, so anything you assign must include them too.

### Node attributes

With any of the `*_attributes` extensions enabled, comrak parses Pandoc-style attribute blocks such as `{#intro .big data-x=1}` off the end of headings, fenced code blocks, inline code, links and images. `attributes` reads them as a Hash of `id`, `classes` and `pairs`, or `nil` when a node has none; `attributes=` replaces them, and accepts `nil` to clear them:

```ruby
doc = Commonmarker.parse("## Intro {#intro .big data-x=1}", options: { extension: { header_attributes: true } })
doc.first_child.attributes
# => {id: "intro", classes: ["big"], pairs: {"data-x" => "1"}}

doc.first_child.attributes = { classes: ["lede"], pairs: { "data-x" => "2" } }
```

Attributes only reach the HTML when the `attributes` render option is on **and** `unsafe` is on, because an attribute block can smuggle in event handlers and the like. If you render untrusted Markdown, leave `attributes` off and apply an allowlist of the parsed values yourself:

```ruby
Commonmarker.to_html("## Intro {#intro .big}", options: {
  extension: { header_attributes: true, header_ids: nil },
  render: { attributes: true, unsafe: true },
})
# => <h2 id="intro" class="big">Intro</h2>
```

## Options and plugins

### Options

Commonmarker accepts the same parse, render, and extensions options that comrak does, as a hash dictionary with symbol keys:

```ruby
Commonmarker.to_html('"Hi *there*"', options:{
  parse: { smart: true },
  render: { hardbreaks: false}
})
```

Note that there is a distinction in comrak for "parse" options and "render" options, which are represented in the tables below. As well, if you wish to disable any-non boolean option, pass in `nil`.

### Parse options

| Name                         | Description                                                                                                                                 | Default |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `smart`                      | Punctuation (quotes, full-stops and hyphens) are converted into 'smart' punctuation.                                                        | `false` |
| `default_info_string`        | The default info string for fenced code blocks.                                                                                             | `""`    |
| `relaxed_tasklist_matching`  | Enables relaxing of the tasklist extension matching, allowing any non-space to be used for the "checked" state instead of only `x` and `X`. | `false` |
| `relaxed_autolinks`          | Enable relaxing of the autolink extension parsing, allowing links to be recognized when in brackets, as well as permitting any url scheme.  | `false` |
| `leave_footnote_definitions` | Allow footnote definitions to remain in their original positions instead of being moved to the document's end (only affects AST)            | `false` |
| `ignore_setext`              | Ignores setext-style headings.                                                                                                              | `false` |
| `sourcepos_chars`            | Use character-based column tracking in source positions instead of byte-based. Relevant for multi-byte UTF-8 documents with `sourcepos`.    | `false` |
| `max_nesting_depth`          | The deepest a node may nest below the document. Deeper documents raise `Commonmarker::NestingDepthExceededError` instead of being parsed.  | `1000`  |
| `tasklist_in_table`          | Allows a task list item to be the sole content of a table cell. Needs the `table` and `tasklist` extensions.                                | `false` |
| `escaped_char_spans`         | Keeps [escaped characters](https://spec.commonmark.org/0.31.2/#backslash-escapes) as `escaped` nodes in the AST. Implied by the render option of the same name. | `false` |

### Render options

| Name                 | Description                                                                                                              | Default      |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------ |
| `hardbreaks`         | [Soft line breaks](http://spec.commonmark.org/0.27/#soft-line-breaks) translate into hard line breaks.                   | `true`       |
| `github_pre_lang`    | GitHub-style `<pre lang="xyz">` is used for fenced code blocks with info tags.                                           | `true`       |
| `full_info_string`   | Gives info string data after a space in a `data-meta` attribute on code blocks.                                          | `false`      |
| `width`              | The wrap column when outputting CommonMark.                                                                              | `80`         |
| `unsafe`             | Allow rendering of raw HTML and potentially dangerous links.                                                             | `false`      |
| `escape`             | Escape raw HTML instead of clobbering it.                                                                                | `false`      |
| `sourcepos`          | Include source position attribute in HTML and XML output.                                                                | `false`      |
| `escaped_char_spans` | Wrap escaped characters in span tags.                                                                                    | `true`       |
| `ignore_empty_links` | Ignores empty links, leaving the Markdown text in place.                                                                 | `false`      |
| `gfm_quirks`         | Outputs HTML with GFM-style quirks; namely, not nesting `<strong>` inlines.                                              | `false`      |
| `prefer_fenced`      | Always output fenced code blocks, even where an indented one could be used.                                              | `false`      |
| `tasklist_classes`   | Add CSS classes to the HTML output of the tasklist extension                                                             | `false`      |
| `compact_html`       | Suppress newlines in pretty-printed HTML output.                                                                         | `false`      |
| `alert_style`        | The style of alert output: `:specific` (`<div class="markdown-alert">`) or `:semantic` (`<aside class="admonition">`). | `:specific` |
| `list_style`         | The bullet list marker used when outputting CommonMark: `:dash` (`-`), `:plus` (`+`) or `:star` (`*`).                | `:dash`     |
| `figure_with_caption` | Renders an image that has a title as a `<figure>`, with the title as its `<figcaption>`.                                 | `false`      |
| `ol_width`           | The minimum ordered list marker width when outputting CommonMark. Values below 3 have no effect.                         | `0`          |
| `experimental_minimize_commonmark` | Drops escapes from CommonMark output when the document still roundtrips without them. Expensive.                         | `false`      |
| `attributes`         | Writes parsed or assigned node attributes into the HTML. Does nothing without `unsafe`, since attributes can carry scripts. | `false`      |

As well, there are several extensions which you can toggle in the same manner:

```ruby
Commonmarker.to_html('"Hi *there*"', options: {
    extension: { footnotes: true, description_lists: true },
    render: { hardbreaks: false }
})
```

### Extension options

| Name                          | Description                                                                                                         | Default |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------- |
| `strikethrough`               | Enables the [strikethrough extension](https://github.github.com/gfm/#strikethrough-extension-) from the GFM spec.   | `true`  |
| `table`                       | Enables the [table extension](https://github.github.com/gfm/#tables-extension-) from the GFM spec.                  | `true`  |
| `autolink`                    | Enables the [autolink extension](https://github.github.com/gfm/#autolinks-extension-) from the GFM spec.            | `true`  |
| `tasklist`                    | Enables the [task list extension](https://github.github.com/gfm/#task-list-items-extension-) from the GFM spec.     | `true`  |
| `superscript`                 | Enables the superscript Comrak extension.                                                                           | `false` |
| `header_ids`                  | Enables the header IDs Comrak extension. from the GFM spec.                                                         | `""`    |
| `header_id_prefix_in_href`    | Also add the prefix to generated `href` attributes pointing to headers.                                             | `false` |
| `footnotes`                   | Enables the footnotes extension per `cmark-gfm`.                                                                    | `false` |
| `inline_footnotes`            | Enables the inline footnotes extension.                                                                             | `false` |
| `description_lists`           | Enables the description lists extension.                                                                            | `false` |
| `front_matter_delimiter`      | Enables the front matter extension.                                                                                 | `""`    |
| `multiline_block_quotes`      | Enables the multiline block quotes extension.                                                                       | `false` |
| `math_dollars`, `math_code`   | Enables the math extension.                                                                                         | `false` |
| `math_latex`                  | Enables the math extension with LaTeX-style delimiters (`\(inline\)`, `\[display\]`).                               | `false` |
| `shortcodes`                  | Enables the shortcodes extension.                                                                                   | `true`  |
| `wikilinks_title_before_pipe` | Enables the wikilinks extension, placing the title before the dividing pipe.                                        | `false` |
| `wikilinks_title_after_pipe`  | Enables the wikilinks extension, placing the title after the dividing pipe.                                         | `false` |
| `underline`                   | Enables the underline extension.                                                                                    | `false` |
| `spoiler`                     | Enables the spoiler extension.                                                                                      | `false` |
| `greentext`                   | Enables the greentext extension.                                                                                    | `false` |
| `subtext`                     | Enables the subtext extension.                                                                                      | `false` |
| `subscript`                   | Enables the subscript extension.                                                                                    | `false` |
| `alerts`                      | Enables the alerts extension.                                                                                       | `false` |
| `cjk_friendly_emphasis`       | Enables the [CJK friendly emphasis](https://github.com/tats-u/markdown-cjk-friendly) extension.                     | `false` |
| `highlight`                   | Enables highlighting via `==`                                                                                       | `false` |
| `insert`                      | Enables the insert extension, rendering `++text++` as `<ins>text</ins>`.                                            | `false` |
| `block_directive`             | Enables the block directive extension.                                                                              | `false` |
| `math_dollars_block`          | Enables multiline display math blocks delimited by `$$` lines. Requires `math_dollars`.                             | `false` |
| `wikilinks_ignore_embeds`     | Ignores wikilink-style embeds (`![[url]]`) when a wikilinks extension is enabled.                                   | `false` |
| `ofm_callouts`                | Enables [Obsidian-style callouts](https://help.obsidian.md/callouts), such as `> [!tip]`.                           | `false` |
| `ofm_comments`                | Enables Obsidian-style `%%comment%%` comments, which are dropped from the output.                                   | `false` |
| `ofm_block_ids`               | Enables Obsidian-style block identifiers (`^abc123` at the end of a block).                                         | `false` |
| `header_attributes`           | Parses `{#id .class key=value}` attribute blocks at the end of ATX and setext headings.                             | `false` |
| `fenced_code_attributes`      | Parses attribute blocks in the info string of fenced code blocks.                                                   | `false` |
| `inline_code_attributes`      | Parses attribute blocks directly after inline code spans.                                                           | `false` |
| `link_attributes`             | Parses attribute blocks directly after links and images.                                                            | `false` |

For more information on these options, see [the comrak documentation](https://github.com/kivikakk/comrak#usage).

### Plugins

In addition to the possibilities provided by generic CommonMark rendering, Commonmarker also supports plugins as a means of
providing further niceties.

#### Syntax Highlighter Plugin

The syntax highlighter plugin is **enabled by default**, using the `"base16-ocean.dark"` theme. It applies syntax highlighting to fenced code blocks that specify a language.

The library comes with [a set of pre-existing themes](https://docs.rs/syntect/5.0.0/syntect/highlighting/struct.ThemeSet.html#implementations) for highlighting code:

- `"base16-ocean.dark"`
- `"base16-eighties.dark"`
- `"base16-mocha.dark"`
- `"base16-ocean.light"`
- `"InspiredGitHub"`
- `"Solarized (dark)"`
- `"Solarized (light)"`

````ruby
code = <<~CODE
  ```ruby
  def hello
    puts "hello"
  end
  ```
CODE

# pass in a theme name from a pre-existing set
puts Commonmarker.to_html(code, plugins: { syntax_highlighter: { theme: "InspiredGitHub" } })

# <pre style="background-color:#ffffff;" lang="ruby"><code>
# <span style="font-weight:bold;color:#a71d5d;">def </span><span style="font-weight:bold;color:#795da3;">hello
# </span><span style="color:#62a35c;">puts </span><span style="color:#183691;">&quot;hello&quot;
# </span><span style="font-weight:bold;color:#a71d5d;">end
# </span>
# </code></pre>
````

To disable this plugin, set the value to `nil`:

````ruby
code = <<~CODE
  ```ruby
  def hello
    puts "hello"
  end
  ```
CODE

Commonmarker.to_html(code, plugins: { syntax_highlighter: nil })

# <pre lang="ruby"><code>def hello
#   puts &quot;hello&quot;
# end
# </code></pre>
````

To output CSS classes instead of `style` attributes, set the `theme` key to `""`:

````ruby
code = <<~CODE
  ```ruby
  def hello
    puts "hello"
  end
CODE

Commonmarker.to_html(code, plugins: { syntax_highlighter: { theme: "" } })

# <pre class="syntax-highlighting"><code><span class="source ruby"><span class="meta function ruby"><span class="keyword control def ruby">def</span></span><span class="meta function ruby"> # <span class="entity name function ruby">hello</span></span>
#   <span class="support function builtin ruby">puts</span> <span class="string quoted double ruby"><span class="punctuation definition string begin ruby">&quot;</span>hello<span class="punctuation definition string end ruby">&quot;</span></span>
# <span class="keyword control ruby">end</span>\n</span></code></pre>
````

To use a custom theme, you can provide a `path` to a directory containing `.tmtheme` files to load:

```ruby
Commonmarker.to_html(code, plugins: { syntax_highlighter: { theme: "Monokai", path: "./themes" } })
```

Syntax highlighters are expensive to build, so Commonmarker builds one per `theme`/`path` combination and keeps it for the life of the process. Theme files in a custom `path` are read the first time that path is used; restart the process to pick up changes to them.

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

```
❯ bundle exec rake benchmark
input size = 3789 bytes

ruby 3.4.0dev (2024-12-25 master f450108330) +PRISM [arm64-darwin24]
Warming up --------------------------------------
  Markly.render_html    11.518k i/100ms
Markly::Node#to_html    11.674k i/100ms
Commonmarker.to_html    21.904k i/100ms
Commonmarker.to_html (no syntax highlighting)
                        24.241k i/100ms
Commonmarker#to_html    23.992k i/100ms
Commonmarker::Node.to_html
                        12.379k i/100ms
Kramdown::Document#to_html
                         2.165k i/100ms
Calculating -------------------------------------
  Markly.render_html    108.072k (± 2.9%) i/s    (9.25 μs/i) -    541.346k in   5.013402s
Markly::Node#to_html    110.790k (± 2.2%) i/s    (9.03 μs/i) -    560.352k in   5.060246s
Commonmarker.to_html    208.564k (± 2.0%) i/s    (4.79 μs/i) -      1.051M in   5.043065s
Commonmarker.to_html (no syntax highlighting)
                        232.082k (± 2.3%) i/s    (4.31 μs/i) -      1.164M in   5.016451s
Commonmarker#to_html    242.197k (± 4.0%) i/s    (4.13 μs/i) -      1.224M in   5.060343s
Commonmarker::Node.to_html
                        115.814k (± 5.9%) i/s    (8.63 μs/i) -    581.813k in   5.041339s
Kramdown::Document#to_html
                         25.364k (± 1.8%) i/s   (39.43 μs/i) -    127.735k in   5.037814s

Comparison:
Commonmarker#to_html:   242196.7 i/s
Commonmarker.to_html (no syntax highlighting):   232082.5 i/s - same-ish: difference falls within error
Commonmarker.to_html:   208563.9 i/s - 1.16x  slower
Commonmarker::Node.to_html:   115813.7 i/s - 2.09x  slower
Markly::Node#to_html:   110790.1 i/s - 2.19x  slower
  Markly.render_html:   108072.0 i/s - 2.24x  slower
Kramdown::Document#to_html:    25363.6 i/s - 9.55x  slower

input size = 3051 bytes

ruby 3.4.0dev (2024-12-25 master f450108330) +PRISM [arm64-darwin24]
Warming up --------------------------------------
  Markly.render_html     2.998k i/100ms
Markly::Node#to_html     3.239k i/100ms
Commonmarker.to_html   383.000 i/100ms
Commonmarker.to_html (no syntax highlighting)
                         2.153k i/100ms
Commonmarker#to_html   383.000 i/100ms
Commonmarker::Node.to_html
                       339.000 i/100ms
Kramdown::Document#to_html
                       441.000 i/100ms
Calculating -------------------------------------
  Markly.render_html     31.171k (± 9.6%) i/s   (32.08 μs/i) -    155.896k in   5.046734s
Markly::Node#to_html     32.142k (± 7.5%) i/s   (31.11 μs/i) -    161.950k in   5.066521s
Commonmarker.to_html      3.839k (± 1.4%) i/s  (260.46 μs/i) -     19.533k in   5.088637s
Commonmarker.to_html (no syntax highlighting)
                         21.034k (± 3.3%) i/s   (47.54 μs/i) -    105.497k in   5.021405s
Commonmarker#to_html      3.712k (± 4.1%) i/s  (269.37 μs/i) -     18.767k in   5.064171s
Commonmarker::Node.to_html
                          3.476k (± 1.4%) i/s  (287.72 μs/i) -     17.628k in   5.072915s
Kramdown::Document#to_html
                          4.977k (± 2.0%) i/s  (200.93 μs/i) -     25.137k in   5.052836s

Comparison:
Markly::Node#to_html:    32141.5 i/s
  Markly.render_html:    31170.9 i/s - same-ish: difference falls within error
Commonmarker.to_html (no syntax highlighting):    21033.8 i/s - 1.53x  slower
Kramdown::Document#to_html:     4976.9 i/s - 6.46x  slower
Commonmarker.to_html:     3839.4 i/s - 8.37x  slower
Commonmarker#to_html:     3712.3 i/s - 8.66x  slower
Commonmarker::Node.to_html:     3475.6 i/s - 9.25x  slower

input size = 11064832 bytes

ruby 3.4.0dev (2024-12-25 master f450108330) +PRISM [arm64-darwin24]
Warming up --------------------------------------
  Markly.render_html     2.000 i/100ms
Markly::Node#to_html     2.000 i/100ms
Commonmarker.to_html     1.000 i/100ms
Commonmarker.to_html (no syntax highlighting)
                         2.000 i/100ms
Commonmarker#to_html     1.000 i/100ms
Commonmarker::Node.to_html
                         1.000 i/100ms
Kramdown::Document#to_html
                         1.000 i/100ms
Calculating -------------------------------------
  Markly.render_html     27.745 (±10.8%) i/s   (36.04 ms/i) -    138.000 in   5.019913s
Markly::Node#to_html     27.557 (±10.9%) i/s   (36.29 ms/i) -    138.000 in   5.054277s
Commonmarker.to_html     13.790 (± 7.3%) i/s   (72.51 ms/i) -     69.000 in   5.015908s
Commonmarker.to_html (no syntax highlighting)
                         28.994 (± 0.0%) i/s   (34.49 ms/i) -    146.000 in   5.036636s
Commonmarker#to_html     14.612 (± 0.0%) i/s   (68.44 ms/i) -     74.000 in   5.066866s
Commonmarker::Node.to_html
                         10.840 (± 0.0%) i/s   (92.25 ms/i) -     55.000 in   5.083457s
Kramdown::Document#to_html
                          6.905 (± 0.0%) i/s  (144.83 ms/i) -     35.000 in   5.071293s

Comparison:
Commonmarker.to_html (no syntax highlighting):       29.0 i/s
  Markly.render_html:       27.7 i/s - same-ish: difference falls within error
Markly::Node#to_html:       27.6 i/s - same-ish: difference falls within error
Commonmarker#to_html:       14.6 i/s - 1.98x  slower
Commonmarker.to_html:       13.8 i/s - 2.10x  slower
Commonmarker::Node.to_html:       10.8 i/s - 2.67x  slower
Kramdown::Document#to_html:        6.9 i/s - 4.20x  slower
```
