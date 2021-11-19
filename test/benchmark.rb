# frozen_string_literal: true

require 'qiita_marker'
require 'github/markdown'
require 'redcarpet'
require 'kramdown'
require 'benchmark'

def dobench(name, &blk)
  puts name
  puts Benchmark.measure(&blk)
end

benchinput = File.open('test/benchinput.md', 'r').read

printf("input size = %<bytes>d bytes\n\n", benchinput.bytesize)

dobench('redcarpet') do
  Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: false, tables: false).render(benchinput)
end

dobench('qiita_marker with to_html') do
  QiitaMarker.render_html(benchinput)
end

dobench('qiita_marker with ruby HtmlRenderer') do
  QiitaMarker::HtmlRenderer.new.render(QiitaMarker.render_doc(benchinput))
end

dobench('kramdown') do
  Kramdown::Document.new(benchinput).to_html(benchinput)
end
