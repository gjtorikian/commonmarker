# commonmarker

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

### Printing to HTML

Simply put, you'll first need to parse a string to receive a `Document` node. You can than print that node to HTML. For example:

``` ruby
require 'commonmarker'

doc = CommonMarker::Node.parse_string('*Hello* world')
puts(doc.to_html)

doc.walk do |node|
  puts node.type
end
```

### Walking the AST

``` ruby
require 'commonmarker'

# parse the files specified on the command line
doc = CommonMarker::Node.parse_string("# The site\n\n [GitHub](https://www.github.com)")

# Walk tree and print out URLs for links
doc.walk do |node|
  if node.type == :link
    printf("URL = %s\n", node.url)
  end
end

# Capitalize all regular text in headers
doc.walk do |node|
  if node.type == :header
    node.walk do |subnode|
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
class MyHtmlRenderer < HtmlRenderer
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
  STDERR.write(w)
  STDERR.write("\n")
end
```

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

## Hacking

After cloning the repo:

```
script/bootstrap
bundle exec rake compile
```

If there were no errors, you're done! Otherwise, make sure to follow the CMark dependency instructions.
