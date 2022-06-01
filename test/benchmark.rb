# frozen_string_literal: true

require "benchmark/ips"
require "qiita_marker"
require "redcarpet"
require "kramdown"
require "benchmark"

benchinput = File.read("test/benchinput.md").freeze

printf("input size = %<bytes>d bytes\n\n", { bytes: benchinput.bytesize })

Benchmark.ips do |x|
  x.report("redcarpet") do
    Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: false, tables: false).render(benchinput)
  end

  x.report("qiita_marker with to_html") do
    QiitaMarker.render_html(benchinput)
  end

  x.report("qiita_marker with to_xml") do
    QiitaMarker.render_html(benchinput)
  end

  x.report("qiita_marker with ruby HtmlRenderer") do
    QiitaMarker::HtmlRenderer.new.render(QiitaMarker.render_doc(benchinput))
  end

  x.report("qiita_marker with render_doc.to_html") do
    QiitaMarker.render_doc(benchinput, :DEFAULT, [:autolink]).to_html(:DEFAULT, [:autolink])
  end

  x.report("kramdown") do
    Kramdown::Document.new(benchinput).to_html(benchinput)
  end

  x.compare!
end
