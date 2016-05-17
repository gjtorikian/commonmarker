require 'test_helper'

class TestRenderer < Minitest::Test
  def setup
    @doc = CommonMarker.render_doc('Hi *there*')
  end

  def test_html_renderer
    renderer = HtmlRenderer.new
    result = renderer.render(@doc)
    assert_equal "<p>Hi <em>there</em></p>\n", result
  end
end
