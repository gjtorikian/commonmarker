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
  focus
  def test_handles_non_utf8_encoding
    str = 'hello: <https://world.com<0x200b>>'
    doc = CommonMarker.render_doc(str, :DEFAULT)
    # ap doc.to_html

    doc.walk do |node|
      ap node
      if node.type == :link
        text_node = node
        text_node = text_node.first_child until %i[text code].include? text_node.type
        ap node.url if node.url.force_encoding('UTF-8').include?(text_node.string_content.force_encoding('UTF-8'))
      end
    end
  end
end
