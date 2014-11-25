commonmarker
============

Ruby wrapper for libcmark (CommonMark parser)

Eventually this will be made into a gem.  For now, it's a work in
progress.

The wrapper assumes that you have installed the libcmark dynamic
library.  It can be found [here](http://github.com/jgm/CommonMark/).

This wrapper uses libcmark's parser, and then uses the node tree
it returns to create a native ruby structure.  The node tree is then
freed, so there are no further worries about memory management.

libcmark's HTML renderer is not used.  Instead, a ruby renderer is
used.  This can easily be customized by creating a subclass.
And new renderers for different output formats are equally easy
to add.

These decisions sacrifice some performance for increased flexibility.
But performance is still excellent (roughly seven times faster than
kramdown).  A 10 MB Markdown file can be parsed and rendered in 2.7
seconds on an Intel Core 2 Duo 2GHz machine.

The library also includes `walk` and `transform` functions for
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

# Capitalize all strings in headers
doc.walk do |node|
  if node.type == :header
    node.walk do |subnode|
      if subnode.type == :str
        subnode.string_content = subnode.string_content.upcase
      end
    end
  end
end

# Transform links to regular text
doc.transform do |node|
  if node.type == :link
    node.children
  end
end

# Render the transformed document to STDOUT
renderer = HtmlRenderer.new(STDOUT)
renderer.render(doc)

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
               node.children, "</h", node.header_level, ">")
      @headerid += 1
    end
  end
end

myrenderer = MyHtmlRenderer.new(STDOUT)
myrenderer.render(doc)
```
