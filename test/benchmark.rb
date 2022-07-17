# frozen_string_literal: true

require "benchmark/ips"
require "commonmarker"
require "redcarpet"
require "kramdown"
require "benchmark"

benchinput = File.read("test/benchinput.md").freeze

printf("input size = %<bytes>d bytes\n\n", { bytes: benchinput.bytesize })

Benchmark.ips do |x|
  x.report("redcarpet") do
    Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: false, tables: false).render(benchinput)
  end

  x.report("commonmarker with to_html") do
    Commonmarker.render_html(benchinput)
  end

  x.report("commonmarker with to_xml") do
    Commonmarker.to_html(benchinput)
  end

  x.report("kramdown") do
    Kramdown::Document.new(benchinput).to_html(benchinput)
  end

  x.compare!
end
