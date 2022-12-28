# frozen_string_literal: true

require "test_helper"

class TestSyntaxHighlighting < Minitest::Test
  # focus
  def test_default
    code = <<~CODE
      ```ruby
      def hello
        puts "hello"
      end
      ```
    CODE

    html = Commonmarker.to_html(code)

    result = <<~HTML
      <pre lang="ruby" style="background-color:#2b303b;"><code>
      <span style="color:#b48ead;">def </span><span style="color:#8fa1b3;">hello
      </span><span style="color:#c0c5ce;">  </span><span style="color:#96b5b4;">puts </span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">hello</span><span style="color:#c0c5ce;">&quot;
      </span><span style="color:#b48ead;">end
      </span>
      </code></pre>
    HTML

    assert_equal(result, html)
  end

  def test_can_disable
    code = <<~CODE
      ```ruby
      def hello
        puts "hello"
      end
      ```
    CODE

    html = Commonmarker.to_html(code, plugins: { syntax_highlighter: nil })

    result = %(<pre lang="ruby"><code>def hello\n  puts &quot;hello&quot;\nend\n</code></pre>\n)

    assert_equal(result, html)
  end
end
