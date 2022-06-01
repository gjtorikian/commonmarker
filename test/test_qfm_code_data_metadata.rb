# frozen_string_literal: true

require("test_helper")

class TestQfmCodeDataMetadata < Minitest::Test
  def test_to_html
    text = <<~MD
      ```ruby:example main.rb
      puts :foo
      ```
    MD
    doc = render_doc(text)
    expected = <<~HTML
      <pre><code data-metadata="ruby:example main.rb">puts :foo
      </code></pre>
    HTML

    assert_equal(expected, doc.to_html(:CODE_DATA_METADATA))
    assert_equal(expected, QiitaMarker::HtmlRenderer.new(options: :CODE_DATA_METADATA).render(doc))
  end

  def test_with_character_reference
    text = <<~MD
      ```ruby:example&#x20;main.rb
      puts :foo
      ```
    MD
    doc = render_doc(text)
    expected = <<~HTML
      <pre><code data-metadata="ruby:example main.rb">puts :foo
      </code></pre>
    HTML

    assert_equal(expected, doc.to_html(:CODE_DATA_METADATA))
    assert_equal(expected, QiitaMarker::HtmlRenderer.new(options: :CODE_DATA_METADATA).render(doc))
  end

  def render_doc(markdown)
    QiitaMarker.render_doc(markdown, :DEFAULT, [])
  end
end
