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

      :::fizz buzz
      second custom block
      :::

      > :::hoge fuga
      > custom block in blockquote
      > :::
    MD
    @doc = QiitaMarker.render_doc(text, [:UNSAFE], [:custom_block])
  end

  def test_to_html
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
      <div data-type="customblock" data-metadata="fizz buzz">
      <p>second custom block</p>
      </div>
      <blockquote>
      <div data-type="customblock" data-metadata="hoge fuga">
      <p>custom block in blockquote</p>
      </div>
      </blockquote>
    HTML

    assert_equal(@expected, @doc.to_html([:UNSAFE], [:custom_block]))
  end

  def test_to_html_with_sourcepos
    @expected = <<~HTML
      <div data-type="customblock" data-metadata="foo bar" data-sourcepos="1:1-12:3">
      <p data-sourcepos="2:1-2:7">message</p>
      <ul data-sourcepos="4:1-6:0">
      <li data-sourcepos="4:1-4:7">list1</li>
      <li data-sourcepos="5:1-6:0">list2</li>
      </ul>
      <pre data-sourcepos="7:1-9:3"><code class="language-ruby">puts 'hello'
      </code></pre>
      <div>html block</div>
      </div>
      <div data-type="customblock" data-metadata="fizz buzz" data-sourcepos="14:1-16:3">
      <p data-sourcepos="15:1-15:19">second custom block</p>
      </div>
      <blockquote data-sourcepos="18:1-20:5">
      <div data-type="customblock" data-metadata="hoge fuga" data-sourcepos="18:3-20:5">
      <p data-sourcepos="19:3-19:28">custom block in blockquote</p>
      </div>
      </blockquote>
    HTML

    assert_equal(@expected, @doc.to_html([:UNSAFE, :SOURCEPOS], [:custom_block]))
  end
end
