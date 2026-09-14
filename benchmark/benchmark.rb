# frozen_string_literal: true

require "benchmark/ips"
require "commonmarker"
require "markly"
require "kramdown"
require "kramdown-parser-gfm"
require "redcarpet"
require "benchmark"

SMALL_FILE = File.read("benchmark/small.md").freeze
SAMPLE_FILE = File.read("benchmark/sample.md").freeze
LARGE_FILE = File.read("benchmark/large.md").freeze

[SMALL_FILE, SAMPLE_FILE, LARGE_FILE].each do |input|
  kramdown_document = Kramdown::Document.new(input, input: "GFM")

  printf("input size = %<bytes>d bytes\n\n", { bytes: input.bytesize })

  Benchmark.ips do |x|
    x.report("Markly.render_html") do
      Markly.render_html(input)
    end

    x.report("Markly::Node#to_html") do
      Markly.parse(input).to_html
    end

    # Redcarpet does not support true commonmarker syntax/spec
    # x.report("Redcarpet::Markdown#render") do
    #   Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true, strikethrough: true, footnotes: true).render(input)
    # end

    x.report("Commonmarker.to_html") do
      Commonmarker.to_html(input)
    end

    x.report("Commonmarker::Node.to_html") do
      Commonmarker.parse(input).to_html
    end

    x.report("Kramdown::Document#to_html") do
      kramdown_document.to_html
    end

    x.compare!
  end
end
