# frozen_string_literal: true

require("test_helper")

class TestQfmCustomBlock < Minitest::Test
  def setup
    text = <<~MD
      :::foo bar
      message

      - list1
      - list2

      ```ruby
      puts 'hello'
      ```

      <div>html block</div>
      :::
    MD
    @doc = QiitaMarker.render_doc(text, [:UNSAFE], [:custom_block])
    @expected = <<~HTML
      <div data-type="customblock" data-metadata="foo bar">
      <p>message</p>
      <ul>
      <li>list1</li>
      <li>list2</li>
      </ul>
      <pre><code class="language-ruby">puts 'hello'
      </code></pre>
      <div>html block</div>
      </div>
    HTML
  end

  def test_to_html
    assert_equal(@expected, @doc.to_html([:UNSAFE], [:custom_block]))
  end
end
