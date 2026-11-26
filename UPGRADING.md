# Upgrading Commonmarker

## Upgrading from 2.x

Commonmarker 3.0 changes what a bare `Commonmarker.to_html(text)` produces, turns `Commonmarker` into a class, tightens two option values, and finishes moving option handling into Rust. Each change is described below along with what to do about it.

### The defaults are now comrak's

2.x enabled a handful of options and the syntax highlighter by default, so `Commonmarker.to_html(text)` with no options produced GitHub-comment-style HTML. 3.0 uses comrak's own defaults instead: plain CommonMark, with no extensions and no plugins. Comrak documents these defaults as compliant with [CommonMark 0.31.2](https://spec.commonmark.org/0.31.2/). Everything in this table is now off unless you turn it on:

| Option                                                      | 2.x default                     | 3.0 default        |
| ----------------------------------------------------------- | ------------------------------- | ------------------ |
| `extension: { strikethrough:, table:, autolink:, tasklist: }` | `true`                          | `false`            |
| `extension: { shortcodes: }`                                | `true`                          | `false`            |
| `extension: { header_ids: }`                                | `""` (on, with no prefix)       | `nil` (off)        |
| `render: { hardbreaks: }`                                   | `true`                          | `false`            |
| `render: { github_pre_lang: }`                              | `true`                          | `false`            |
| `render: { escaped_char_spans: }`                           | `true`                          | `false`            |
| `render: { width: }`                                        | `80`                            | `0` (no wrapping)  |
| `plugins: { syntax_highlighter: }`                          | `{ theme: "base16-ocean.dark" }` | `nil` (off)        |

The visible effects, in rough order of how often they bite:

- Soft line breaks stay soft. A newline inside a paragraph no longer becomes `<br />`.
- Headings have no `id` attribute and no anchor link.
- Fenced code blocks render as `<pre><code class="language-ruby">` instead of `<pre lang="ruby">`, and are not syntax highlighted.
- `~~strikethrough~~`, tables, bare URLs, `- [ ]` task lists, and `:emoji:` shortcodes render as literal text.
- `to_commonmark` no longer wraps lines at 80 columns.

**To get the 2.x output back**, pass the old defaults explicitly. If you convert many documents, build one `Commonmarker` instance with them (see the next section) rather than passing them on every call:

```ruby
LEGACY_OPTIONS = {
  render: { hardbreaks: true, github_pre_lang: true, width: 80, escaped_char_spans: true },
  extension: { strikethrough: true, table: true, autolink: true, tasklist: true, shortcodes: true, header_ids: "" },
}.freeze
LEGACY_PLUGINS = { syntax_highlighter: { theme: "base16-ocean.dark" } }.freeze

Commonmarker.to_html(text, options: LEGACY_OPTIONS, plugins: LEGACY_PLUGINS)
```

**For GitHub Flavored Markdown**, enable what comrak's own `--gfm` flag enables:

```ruby
Commonmarker.to_html(text, options: {
  extension: { strikethrough: true, table: true, autolink: true, tasklist: true },
  render: { github_pre_lang: true, gfm_quirks: true },
})
```

Two smaller consequences of the new defaults:

- `nil` now always means "the default". In 2.x, `render: { hardbreaks: nil }` gave comrak's default (`false`) while leaving the key out gave Commonmarker's (`true`). Those are now the same thing, for every option.
- `Commonmarker::Config::OPTIONS` reports the new defaults, with `nil` for the string options that are off (`default_info_string`, `header_ids`, `front_matter_delimiter`), and `Commonmarker::Config::PLUGINS` is `{ syntax_highlighter: nil }`. Both are snapshots for introspection; passing them back in changes nothing.

### `Commonmarker` is a class

`Commonmarker` was a module. It is now a class, so that `Commonmarker.new(options:, plugins:)` can validate a configuration once and reuse it across calls and threads:

```ruby
MARKDOWN = Commonmarker.new(options: { parse: { smart: true } }, plugins: { syntax_highlighter: {} })

MARKDOWN.to_html(text)
MARKDOWN.to_commonmark(text)
MARKDOWN.parse(text)
```

`Commonmarker.to_html`, `Commonmarker.parse`, and `Node#to_html` keep working as before. What breaks:

- `module Commonmarker ... end` raises `TypeError` when the file loads. Reopen it with `class Commonmarker` instead.
- `include Commonmarker` and `extend Commonmarker` no longer work. Call `Commonmarker.to_html` directly.

### `alert_style` and `list_style` take Symbols

Both pick from a fixed set of names, and now take a Symbol like option keys, node types, and list types do everywhere else in the API:

```ruby
Commonmarker.to_html(md, options: { render: { alert_style: :semantic } })  # was "semantic"
doc.to_commonmark(options: { render: { list_style: :plus } })               # was "plus"
```

- A String raises `TypeError`: ``render option `:list_style` must be Symbol; got String``.
- An unknown name raises `ArgumentError` instead of silently falling back to the default: ``render option `:list_style` must be one of :dash, :plus, :star; got :bullet``.
- `Commonmarker::Config::OPTIONS` reports these defaults as `:specific` and `:dash`.

Free-form string options (`header_ids`, `front_matter_delimiter`, `default_info_string`, and the highlighter `theme`) still take Strings.

### Options are processed in Rust

Option and plugin handling moved out of Ruby, which removed some Ruby-side internals:

- `Commonmarker::Config.process_options` and `Commonmarker::Config.process_plugins` are gone. Pass your Hash to `Commonmarker.new`, which validates it up front.
- `Commonmarker::Utils` and `Commonmarker::Constants` are gone.
- `Commonmarker::Config::OPTIONS` no longer has a `:format` key.

Validation still raises `TypeError` for a value of the wrong type. A value of the right type that is not allowed (an unknown theme, a negative width, an unknown `list_style`) raises `ArgumentError`.

### comrak 1.x output changes

3.0 is built on comrak 1.2, where 2.x used 0.56. Comrak 1.0 formally specified footnotes, math, superscript and subscript, description lists, header IDs, wikilinks, alerts, tables, autolinks, and task lists, and each spec changed output in edge cases. Among them: duplicate footnote definitions follow first-wins, empty headings get a `-1` id, and lists, footnote definitions, and fenced containers stop nesting at 100 levels. If you snapshot-test HTML output, expect some diffs. [Comrak's changelog](https://github.com/kivikakk/comrak/blob/main/CHANGELOG.md) has the full list.
