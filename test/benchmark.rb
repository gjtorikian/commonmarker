# frozen_string_literal: true

require "benchmark/ips"
require "commonmarker"
require "redcarpet"
require "kramdown"
require 'kramdown-parser-gfm'
require "benchmark"

benchinput = File.read("test/benchinput.md").freeze

printf("input size = %<bytes>d bytes\n\n", { bytes: benchinput.bytesize })

Benchmark.ips do |x|
  x.report("redcarpet") do
    Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true, strikethrough: true, footnotes: true).render(benchinput)
  end

  x.report("commonmarker with to_html") do
    Commonmarker.to_html(benchinput)
  end

  x.report("kramdown") do
    Kramdown::Document.new(benchinput, input: 'GFM').to_html
  end

  x.compare!
end
