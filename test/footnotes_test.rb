# frozen_string_literal: true

require "test_helper"

class FootnotesTest < Minitest::Test
  def test_to_html
    md = <<~MARKDOWN
      Let's render some footnotes[^1]

      [^1]: This is a footnote
    MARKDOWN
    expected = <<~HTML
      <p>Let's render some footnotes<sup class="footnote-ref"><a href="#fn-1" id="fnref-1" data-footnote-ref>1</a></sup></p>
      <section class="footnotes" data-footnotes>
      <ol>
      <li id="fn-1">
      <p>This is a footnote <a href="#fnref-1" class="footnote-backref" data-footnote-backref data-footnote-backref-idx="1" aria-label="Back to reference 1">↩</a></p>
      </li>
      </ol>
      </section>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { footnotes: true } }))
  end

  def test_inline_to_html
    md = <<~MARKDOWN
      Let's render some footnotes^[This is a footnote]
    MARKDOWN
    expected = <<~HTML
      <p>Let's render some footnotes<sup class="footnote-ref"><a href="#fn-__inline_1" id="fnref-__inline_1" data-footnote-ref>1</a></sup></p>
      <section class="footnotes" data-footnotes>
      <ol>
      <li id="fn-__inline_1">
      <p>This is a footnote <a href="#fnref-__inline_1" class="footnote-backref" data-footnote-backref data-footnote-backref-idx="1" aria-label="Back to reference 1">↩</a></p>
      </li>
      </ol>
      </section>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { footnotes: true, inline_footnotes: true } }))
  end

  def test_leave_footnote_definitions_option
    md = <<~MARKDOWN
      Here is a footnote reference.[^1]

      [^1]: Here is the footnote.

      Here is a longer footnote reference.[^ref]

      [^ref]: Here is another footnote.
    MARKDOWN

    # Without leave_footnote_definitions, footnote definitions are moved to the end
    doc_default = Commonmarker.parse(
      md,
      options: { extension: { footnotes: true } },
    )

    nodes_default = []
    child = doc_default.first_child
    while child
      nodes_default << child.type
      child = child.next_sibling
    end

    # Default behavior: footnotes moved to end
    assert_equal(
      [:paragraph, :paragraph, :footnote_definition, :footnote_definition],
      nodes_default,
      "Without leave_footnote_definitions, footnote definitions should be moved to the end",
    )

    # With leave_footnote_definitions: true, footnote definitions stay in original positions in AST
    doc_leave = Commonmarker.parse(
      md,
      options: { parse: { leave_footnote_definitions: true }, extension: { footnotes: true } },
    )

    nodes_leave = []
    child = doc_leave.first_child
    while child
      nodes_leave << child.type
      child = child.next_sibling
    end

    # With option: footnotes stay in original positions (interleaved)
    assert_equal(
      [:paragraph, :footnote_definition, :paragraph, :footnote_definition],
      nodes_leave,
      "With leave_footnote_definitions, footnote definitions should remain in their original positions",
    )
  end
end
