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
    node.each_child do |child|
      node.insert_before(child)
    end
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
