commonmarker
============

Ruby wrapper for libcmark (CommonMark parser)

Eventually this will be made into a gem.  For now, it's a work in
progress.

The wrapper assumes that you have installed the libcmark dynamic
library.  It can be found [here](http://github.com/jgm/CommonMark/).

The parser returns a Node object that wraps pointers to the
structures allocated by libcmark.  Access to libcmark's fast
HTML renderer is provided (the HtmlNativeRenderer class). For
more flexibility, a ruby HtmlRenderer class is also provided,
which can be customized through subclassing.  New renderers for
any output format can easily be added.

Some rough benchmarks:

```
input size = 10031600 bytes

commonmarker with HtmlNativeRenderer   0.188 s
commonmarker with ruby HtmlRenderer    2.418 s
redcarpet                              0.127 s
kramdown                              14.700 s
```

The library also includes a `walk` function for
manipulating the AST produced by the parser.  So, for example,
you can easily change all the links to plain text, or demote
level 5 headers to regular paragraphs, prior to rendering.

Usage example:

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

# Render the transformed document to a string
renderer = HtmlNativeRenderer.new
html = renderer.render(doc)
print(html)

# Print any warnings to STDERR
renderer.warnings.each do |w|
  STDERR.write(w)
  STDERR.write("\n")
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

# free allocated memory when you're done
doc.free
```
