# frozen_string_literal: true

require('test_helper')

class TestQfmCodeDataMetadata < Minitest::Test
  def setup
    text = <<~MD
      ```ruby:example.rb
      puts :foo
      ```
    MD
    @doc = QiitaMarker.render_doc(text, :DEFAULT, [])
    @expected = <<~HTML
      <pre><code data-metadata="ruby:example.rb">puts :foo
      </code></pre>
    HTML
  end

  def test_to_html
    assert_equal(@expected, @doc.to_html(:CODE_DATA_METADATA))
  end

  def test_html_renderer
    assert_equal(@expected, QiitaMarker::HtmlRenderer.new(options: :CODE_DATA_METADATA).render(@doc))
  end
end
