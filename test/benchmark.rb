# frozen_string_literal: true

require "benchmark/ips"
require "commonmarker"
require "markly"
require "kramdown"
require "kramdown-parser-gfm"
require "redcarpet"
require "benchmark"

benchinput = File.read("test/benchinput.md").freeze

printf("input size = %<bytes>d bytes\n\n", { bytes: benchinput.bytesize })

Benchmark.ips do |x|
  x.report("Markly.render_html") do
    Markly.render_html(benchinput)
  end

  x.report("Markly::Node#to_html") do
    Markly.parse(benchinput).to_html
  end

  # Redcarpet is faster, but does not support true commonmarker syntax
  # x.report("Redcarpet::Markdown#render") do
  #   Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true, strikethrough: true, footnotes: true).render(benchinput)
  # end

  x.report("Commonmarker.to_html") do
    Commonmarker.to_html(benchinput)
  end

  x.report("Commonmarker::Node.to_html") do
    Commonmarker.parse(benchinput).to_html
  end

  x.report("Kramdown::Document#to_html") do
    Kramdown::Document.new(benchinput, input: "GFM").to_html
  end

  x.compare!
end
