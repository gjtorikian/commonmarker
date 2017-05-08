# CommonMarker

[![Build Status](https://travis-ci.org/gjtorikian/commonmarker.svg)](https://travis-ci.org/gjtorikian/commonmarker) [![Gem Version](https://badge.fury.io/rb/commonmarker.svg)](http://badge.fury.io/rb/commonmarker)

Ruby wrapper for [libcmark](https://github.com/jgm/CommonMark),
the reference parser for CommonMark. It passes all of the C tests, and is therefore spec-complete.

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
CommonMarker.render_html('Hi *there*', :DEFAULT)
# <p>Hi <em>there</em></p>\n
```

The second argument is optional--[see below](#options) for more information.

### Generating a document

You can also parse a string to receive a `Document` node. You can then print that node to HTML, iterate over the children, and other fun node stuff. For example:

``` ruby
require 'commonmarker'

doc = CommonMarker.render_doc('*Hello* world', :DEFAULT)
puts(doc.to_html) # <p>Hi <em>there</em></p>\n

doc.walk do |node|
  puts node.type # [:document, :paragraph, :text, :emph, :text]
end
```

The second argument is optional--[see below](#options) for more information.

#### Example: walking the AST

You can use `walk` or `each` to iterate over nodes:

- `walk` will iterate on a node and recursively iterate on a node's children.
- `each` will iterate on a node and its children, but no further.

``` ruby
require 'commonmarker'

# parse the files specified on the command line
doc = CommonMarker.render_doc("# The site\n\n [GitHub](https://www.github.com)")

# Walk tree and print out URLs for links
doc.walk do |node|
  if node.type == :link
    printf("URL = %s\n", node.url)
  end
end

# Capitalize all regular text in headers
doc.walk do |node|
  if node.type == :header
    node.each do |subnode|
      if subnode.type == :text
        subnode.string_content = subnode.string_content.upcase
      end
    end
  end
end

# Transform links to regular text
doc.walk do |node|
  if node.type == :link
    node.insert_before(node.first_child)
    node.delete
  end
end
```

### Creating a custom renderer

You can also derive a class from CommonMarker's `HtmlRenderer` class. This produces slower output, but is far more customizable. For example:

``` ruby
class MyHtmlRenderer < CommonMarker::HtmlRenderer
  def initialize
    super
    @headerid = 1
  end

  def header(node)
    block do
      out("<h", node.header_level, " id=\"", @headerid, "\">",
               :children, "</h", node.header_level, ">")
      @headerid += 1
    end
  end
end

# this renderer prints directly to STDOUT, instead
# of returning a string
myrenderer = MyHtmlRenderer.new
print(myrenderer.render(doc))

# Print any warnings to STDERR
renderer.warnings.each do |w|
  STDERR.write("#{w}\n")
end
```

## Options

CommonMarker accepts the same options that CMark does, as symbols. Note that there is a distinction in CMark for "parse" options and "render" options, which are represented in the tables below.

### Parse options

| Name  |  Description |
|-------|--------------|
| `:DEFAULT`  | The default parsing system.  
| `:SMART`  | Use smart punctuation (curly quotes, etc.).
| `:VALIDATE_UTF8`  | Replace illegal sequences with the replacement character `U+FFFD`.
| `:LIBERAL_HTML_TAG`  | Support liberal parsing of inline HTML tags.

### Render options

| Name  |  Description |
|-------|--------------|
| `:DEFAULT`  | The default rendering system.
| `:SOURCEPOS` |  Include source position in rendered HTML.
| `:HARDBREAKS`  | Treat `\n` as hardbreaks (by adding `<br/>`).
| `:SAFE`  | Suppress raw HTML and unsafe links.

### Passing options

To apply a single option, pass it in as a symbol argument:

``` ruby
CommonMarker.render_doc("\"Hello,\" said the spider.", :SMART)
# <p>“Hello,” said the spider.</p>\n
```

To have multiple options applied, pass in an array of symbols:

``` ruby
CommonMarker.render_html("\"'Shelob' is my name.\"", [:HARDBREAKS, :SOURCEPOS])
```

For more information on these options, see [the CMark documentation](http://git.io/vlQii).

## Hacking

After cloning the repo:

```
script/bootstrap
bundle exec rake compile
```

If there were no errors, you're done! Otherwise, make sure to follow the CMark dependency instructions.

## Benchmarks

Some rough benchmarks:

```
$ bundle exec rake benchmark

input size = 11063727 bytes

redcarpet
  0.070000   0.020000   0.090000 (  0.079641)
github-markdown
  0.070000   0.010000   0.080000 (  0.083535)
commonmarker with to_html
  0.100000   0.010000   0.110000 (  0.111947)
commonmarker with ruby HtmlRenderer
  1.830000   0.030000   1.860000 (  1.866203)
kramdown
  4.610000   0.070000   4.680000 (  4.678398)
```
