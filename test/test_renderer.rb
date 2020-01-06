# frozen_string_literal: true

require 'test_helper'

class TestRenderer < Minitest::Test
  class CustomCommonMarker < CommonMarker::HtmlRenderer
    attr_accessor :link_attributes

    def link(node)
      # Based on https://github.com/gjtorikian/commonmarker/blob/1fe234820a77cb3f2b26b47971d229d0da92d652/lib/commonmarker/renderer/html_renderer.rb#L130-L136
      attributes = { href: node.url.nil? ? '' : escape_href(node.url) }
      attributes[:title] = escape_html(node.title) if node.title
      attributes.merge!(link_attributes || {})
      formatted_attrs = attributes.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
      out("<a #{formatted_attrs}>", :children, '</a>')
    end
  end

  def setup
    @doc = CommonMarker.render_doc('Hi *there*')
  end

  def test_html_renderer
    renderer = HtmlRenderer.new
    result = renderer.render(@doc)
    assert_equal "<p>Hi <em>there</em></p>\n", result
  end

  def test_multiple_tables
    content = <<~DOC
      | Input       | Expected         | Actual    |
      | ----------- | ---------------- | --------- |
      | One         | Two              | Three     |

      | Header   | Row  | Example |
      | :------: | ---: | :------ |
      | Foo      | Bar  | Baz     |
    DOC
    doc = CommonMarker.render_doc(content, :DEFAULT, %i[autolink table tagfilter])
    results = CommonMarker::HtmlRenderer.new.render(doc)
    assert_equal 2, results.scan(/<tbody>/).size
  end

  def test_custom_render_speed
    content = <<~DOC
      **wow**

      [foo]: /url "title"

      [foo]
    DOC
    doc = CommonMarker.render_doc(content, :DEFAULT, %i[autolink table tagfilter])
    results = CustomCommonMarker.new.render(doc)
    output = "<p><strong>wow</strong></p>\n<p><a href=\"/url\" title=\"title\">foo</a></p>\n"
    assert_equal output, results
  end
end
