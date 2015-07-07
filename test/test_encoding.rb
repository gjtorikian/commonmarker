require 'test_helper'

class TestEncoding < Minitest::Test
  # see http://git.io/vq4FR
  def test_encoding
    contents = File.read(File.join(FIXTURES_DIR, 'curly.md'))
    render = CommonMarker.render_html(contents, :smart)
    assert_equal render.rstrip, '<p>This curly quote “makes commonmarker throw an exception”.</p>'
  end
end
