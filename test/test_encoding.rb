# frozen_string_literal: true

require "test_helper"

class TestEncoding < Minitest::Test
  # see http://git.io/vq4FR
  def test_encoding
    contents = fixtures_file("curly.md")
    render = Commonmarker.to_html(contents, :SMART)

    assert_equal("<p>This curly quote “makes commonmarker throw an exception”.</p>", render.rstrip)
  end

  def test_string_content_is_utf8
    html = Commonmarker.to_html("Hi *there*")
    assert_equal("<p>Hi <strong>there</strong>", html)
    assert_equal("UTF-8", html.encoding.name)
  end
end
