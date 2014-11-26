require './commonmarker'

doc = Node.parse_file(ARGF)

# Walk tree and print URLs for links
doc.walk do |node|
  if node.type == :link
    printf("URL = %s\n", node.url)
  end
end

# Capitalize regular text in headers
doc.walk do |node|
  if node.type == :header
    node.walk do |subnode|
      if subnode.type == :text
        subnode.string_content = subnode.string_content.upcase
      end
    end
  end
end

# Walk tree and transform links to regular text
doc.transform do |node|
  if node.type == :link
    node.children
  end
end

renderer = HtmlRenderer.new(STDOUT)
renderer.render(doc)

renderer.warnings.each do |w|
  STDERR.write(w)
  STDERR.write("\n")
end

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

# def markdown_to_html(s)
#   len = s.bytes.length
#   CMark::cmark_markdown_to_html(s, len)
# end
# print markdown_to_html(STDIN.read())
