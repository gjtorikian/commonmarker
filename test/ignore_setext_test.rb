# frozen_string_literal: true

require "test_helper"

class IgnoreSetextTest < Minitest::Test
  def test_setext_headers_parsed_by_default
    md = <<~MARKDOWN
      This is an H1
      =============

      This is an H2
      -------------
    MARKDOWN

    expected = <<~HTML
      <h1>This is an H1</h1>
      <h2>This is an H2</h2>
    HTML

    opts = {
      render: { hardbreaks: false },
      extension: { header_ids: nil },
    }

    assert_equal(expected, Commonmarker.to_html(md, options: opts))
  end

  def test_ignore_setext_headers
    md = <<~MARKDOWN
      This is an H1
      =============

      This is an H2
      -------------
    MARKDOWN

    expected = <<~HTML
      <p>This is an H1<br />
      =============</p>
      <p>This is an H2</p>
      <hr />
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { parse: { ignore_setext: true } }))
  end
end
