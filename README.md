commonmarker
============

Ruby wrapper for [libcmark](https://github.com/jgm/CommonMark),
the reference parser for CommonMark.  The gem includes sources
for the C library (currently from commit 677a22519a), so the
library does not need to be installed independently.

The parser returns a `Node` object that wraps pointers to the
structures allocated by libcmark.  Access to libcmark's fast
HTML renderer is provided (the `to_html` method). For
more flexibility, a ruby `HtmlRenderer` class is also provided,
which can be customized through subclassing.  New renderers for
any output format can easily be added.

To install:

    rake install

or

    gem build commonmarker.gemspec
    gem install commonmark-VERSION.gem

Simple usage example:

``` ruby
require './commonmarker'

doc = Node.parse_string("*Hello* world")
print(doc.to_html)
doc.free
```

Some rough benchmarks:

```
input size = 10031600 bytes

redcarpet                              0.13 s
commonmarker with to_html              0.17 s
commonmarker with ruby HtmlRenderer    2.58 s
kramdown                              14.21 s
```

The library also includes a `walk` function for walking the
AST produced by the parser, and either transforming it or
extracting information.  So, for example, you can easily print out all
the URLs linked to in a document, or change all the links to plain text,
or demote level 5 headers to regular paragraphs.

More complex usage example:

``` ruby
require './commonmarker'

# parse the files specified on the command line
doc = Node.parse_file(ARGF)

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

# Create a custom renderer.
class MyHtmlRenderer < HtmlRenderer
  def initialize(stream)
    super
    @headerid = 1
  end
  def header(node)
    block do
      self.out("<h", node.header_level, " id=\"", @headerid, "\">",
               :children, "</h", node.header_level, ">")
      @headerid += 1
    end
  end
end

# this renderer prints directly to STDOUT, instead
# of returning a string
myrenderer = MyHtmlRenderer.new(STDOUT)
myrenderer.render(doc)

# Print any warnings to STDERR
renderer.warnings.each do |w|
  STDERR.write(w)
  STDERR.write("\n")
end

# free allocated memory when you're done
doc.free
```
