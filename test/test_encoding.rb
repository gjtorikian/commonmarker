require 'test_helper'

class TestEncoding < Minitest::Test
  def test_encoding
    contents = File.read(File.join(FIXTURES_DIR, 'curly.md'))
    render = CommonMarker.render_html(contents, :smart)
    assert_equal render.rstrip, "<p>This curly quote \\xE2\\x80\\x9Cmakes commonmarker throw an exception\\xE2\\x80\\x9D.</p>"
  end
end
