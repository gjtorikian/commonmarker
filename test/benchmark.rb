require 'commonmarker'
require 'redcarpet'
require 'kramdown'
require 'benchmark'

def dobench(name, &blk)
  puts name
  puts Benchmark.measure(&blk)
end

benchinput = File.open('test/benchinput.md', 'r').read()

printf("input size = %d bytes\n\n", benchinput.bytesize)

dobench('commonmarker with to_html') do
  CommonMarker::Node.parse_string(benchinput).to_html
end

# dobench('commonmarker with ruby HtmlRenderer') do
#   CommonMarker::HtmlRenderer.new.render(CommonMarker::Node.parse_string(benchinput))
# end

dobench('redcarpet') do
  Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: false, tables: false).render(benchinput)
end

dobench('kramdown') do
  Kramdown::Document.new(benchinput).to_html(benchinput)
end
