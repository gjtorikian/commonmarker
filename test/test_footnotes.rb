# frozen_string_literal: true

require 'test_helper'

class TestFootnotes < Minitest::Test
  def setup
    @doc = Markly.parse("Hello[^hi].\n\n[^hi]: Hey!\n", flags: Markly::FOOTNOTES)
    @expected = <<~HTML
      <p>Hello<sup class="footnote-ref"><a href="#fn-hi" id="fnref-hi" data-footnote-ref>1</a></sup>.</p>
      <section class="footnotes" data-footnotes>
      <ol>
      <li id="fn-hi">
      <p>Hey! <a href="#fnref-hi" class="footnote-backref" data-footnote-backref aria-label="Back to content">↩</a></p>
      </li>
      </ol>
      </section>
    HTML
  end

  def test_to_html
    assert_equal @expected, @doc.to_html
  end

  # def test_html_renderer
  #   assert_equal @expected, Markly::Renderer::HTML.new.render(@doc)
  # end
end
