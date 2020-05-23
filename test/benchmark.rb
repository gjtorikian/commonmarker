# frozen_string_literal: true

require 'markly'
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

dobench('github-markdown') do
  GitHub::Markdown.render(benchinput)
end

dobench('markly with to_html') do
  Markly.render_html(benchinput)
end

dobench('markly with ruby HtmlRenderer') do
  Markly::HtmlRenderer.new.render(Markly.parse(benchinput))
end

dobench('kramdown') do
  Kramdown::Document.new(benchinput).to_html(benchinput)
end
