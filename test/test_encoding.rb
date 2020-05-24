# frozen_string_literal: true

require 'test_helper'

class TestEncoding < Minitest::Test
  # see http://git.io/vq4FR
  def test_encoding
    contents = fixtures_file('curly.md')
    doc = Markly.parse(contents, flags: Markly::SMART)
    render = doc.to_html
    assert_equal render.rstrip, '<p>This curly quote “makes markly throw an exception”.</p>'
  end

  def test_string_content_is_utf8
    doc = Markly.parse('Hi *there*')
    text = doc.first_child.last_child.first_child
    assert_equal text.string_content, 'there'
    assert_equal text.string_content.encoding.name, 'UTF-8'
  end
end
