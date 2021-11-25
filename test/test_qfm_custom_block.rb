# frozen_string_literal: true

require('test_helper')

class TestQfmCustomBlock < Minitest::Test
  def setup
    text = <<~MD
      :::foo bar
      message
      :::
    MD
    @doc = QiitaMarker.render_doc(text, :DEFAULT, %i[custom_block])
    @expected = <<~HTML
      <div data-type="customblock" data-metadata="foo bar">
      <p>message</p>
      </div>
    HTML
  end

  def test_to_html
    assert_equal(@expected, @doc.to_html(:DEFAULT, %i[custom_block]))
  end
end
