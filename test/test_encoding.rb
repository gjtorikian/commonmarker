# frozen_string_literal: true

require 'test_helper'

class TestEncoding < Minitest::Test
  # see http://git.io/vq4FR
  def test_encoding
    contents = fixtures_file('curly.md')
    doc = CommonMarker.render_doc(contents, :SMART)
    render = doc.to_html
    assert_equal('<p>This curly quote “makes commonmarker throw an exception”.</p>', render.rstrip)

    render = doc.to_xml
    assert_includes(render, '<text xml:space="preserve">This curly quote “makes commonmarker throw an exception”.</text>')
  end

  def test_string_content_is_utf8
    doc = CommonMarker.render_doc('Hi *there*')
    text = doc.first_child.last_child.first_child
    assert_equal('there', text.string_content)
    assert_equal('UTF-8', text.string_content.encoding.name)
  end

  def test_handles_non_utf8_encoding
    str = String.new("hello: <https://world.com\u200b>", encoding: Encoding::ASCII_8BIT)
    refute_equal str.encoding, Encoding::UTF_8

    doc = CommonMarker.render_doc(str, :DEFAULT)
    html = doc.to_html

    assert_equal html.encoding, Encoding::UTF_8
    assert_equal("<p>hello: <a href=\"https://world.com%E2%80%8B\">https://world.com​</a></p>\n", html)
  end
end
