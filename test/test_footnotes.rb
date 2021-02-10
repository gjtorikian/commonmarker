# frozen_string_literal: true

require 'test_helper'

class TestFootnotes < Minitest::Test
  def setup
    @doc = CommonMarker.render_doc("Hello[^hi].\n\n[^hi]: Hey!\n", :FOOTNOTES)
    @expected = <<~HTML
      <p>Hello<sup class="footnote-ref"><a href="#fn1" id="fnref1">1</a></sup>.</p>
      <section class="footnotes">
      <ol>
      <li id="fn1">
      <p>Hey! <a href="#fnref1" class="footnote-backref">↩</a></p>
      </li>
      </ol>
      </section>
    HTML
  end

  def test_to_html
    assert_equal @expected, @doc.to_html
  end

  def test_html_renderer
    assert_equal @expected, CommonMarker::HtmlRenderer.new.render(@doc)
  end
        
  def test_render_html
    md = <<~MARKDOWN
      # footnotes
      Let's render some footnotes[^1]

      [^1]: This is a footnote
    MARKDOWN
    expected = <<~HTML
      <h1>footnotes</h1>
      <p>Let's render some footnotes<sup class="footnote-ref"><a href="#fn1" id="fnref1">1</a></sup></p>
      <section class="footnotes">
      <ol>
      <li id="fn1">
      <p>This is a footnote <a href="#fnref1" class="footnote-backref">↩</a></p>
      </li>
      </ol>
      </section>
    HTML
    assert_equal expected, CommonMarker.render_html(md, :FOOTNOTES)
  end
end
