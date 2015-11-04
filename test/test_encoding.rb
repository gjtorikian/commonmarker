require 'test_helper'

class TestEncoding < Minitest::Test
  # see http://git.io/vq4FR
  def test_encoding
    contents = File.read(File.join(FIXTURES_DIR, 'curly.md'))
    doc = CommonMarker.render_doc(contents, :smart)
    render = doc.to_html
    assert_equal render.rstrip, '<p>This curly quote “makes commonmarker throw an exception”.</p>'
  end
end
