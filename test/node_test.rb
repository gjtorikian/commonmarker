# frozen_string_literal: true

require "test_helper"

class NodeTest < Minitest::Test
  def setup
    @document = Commonmarker.parse("Hi *there*. This has __many nodes__!")
  end

  def test_knows_type
    assert_equal(:document, @document.type)
  end

  def test_knows_first_child
    assert_equal(:paragraph, @document.first_child.type)
  end

  def test_knows_next_sibling
    assert_equal(:emph, @document.first_child.first_child.next_sibling.type)
  end

  def test_knows_next_siblings_first_child
    text = <<~STR
      # Hello World!

      This is an example of *CommonMarker*.
    STR
    doc = Commonmarker.parse(text)

    assert_equal(:heading, doc.first_child.type)
    assert_equal(:heading, doc.first_child.type)
    assert_equal(:emph, doc.first_child.next_sibling.first_child.next_sibling.type)
  end

  def test_can_insert_before_node
    strong = Commonmarker::Node.new(:strong)

    assert_equal(:strong, strong.type)
    assert_equal(:paragraph, @document.first_child.type)
    assert_equal(:paragraph, @document.first_child.parent.first_child.type)

    assert(@document.first_child.insert_before(strong))
    assert_equal(strong.type, @document.first_child.type)
    assert_match(%r{<strong></strong>\n<p>Hi <em>there</em>}, @document.to_html)
  end

  def test_can_insert_after_node
    paragraph = Commonmarker::Node.new(:paragraph)

    assert(@document.first_child.insert_after(paragraph))
    assert_match(%r{strong>many nodes<\/strong>!<\/p>\n<p><\/p>\n}, @document.to_html)
  end

  def test_can_prepend_child
    code = Commonmarker::Node.new(:code, num_backticks: 1, literal: "")

    assert(@document.first_child.prepend_child(code))
    assert_match(%r{<p><code><\/code>Hi <em>there<\/em>}, @document.to_html)
  end

  def test_can_append_child
    node = Commonmarker::Node.new(:strong)

    assert(@document.first_child.append_child(node))
    assert_match(%r{!<strong><\/strong><\/p>\n}, @document.to_html)
  end

  def test_can_render_back_to_commonmark
    strikethrough_node = Commonmarker::Node.new(:strikethrough)
    text_node = Commonmarker::Node.new(:text)
    text_node.string_content = "bazinga"

    strikethrough_node.append_child(text_node)

    assert(@document.first_child.first_child.replace(strikethrough_node))

    assert_match(/~~bazinga~~\*there\*/, @document.to_commonmark)
  end

  def test_last_child
    assert_equal(:paragraph, @document.last_child.type)
  end

  def test_parent
    assert_equal(:document, @document.first_child.parent.type)
  end

  def test_next_sibling
    assert_equal(:emph, @document.first_child.first_child.next_sibling.type)
  end

  def test_previous_sibling
    assert_equal(:text, @document.first_child.first_child.next_sibling.previous_sibling.type)
  end

  def test_delete
    emph = @document.first_child.first_child.next_sibling
    emph.delete

    assert_match(%r{<p>Hi . This has <strong>many nodes</strong>!</p>\n}, @document.to_html)
  end

  def test_node_html_with_plugins
    code = <<~CODE
      ```ruby
      puts "hello"
      ```
    CODE

    plugins = { syntax_highlighter: { theme: "InspiredGitHub" } }

    result = Commonmarker.to_html(code, plugins: plugins)

    doc = Commonmarker.parse(code)

    assert_equal(result, doc.to_html(plugins: plugins))
  end

  class StringContentTest < Minitest::Test
    def setup
      @document = Commonmarker.parse("**HELLO!** \n***\n This has `nodes`!")
      @paragraph = @document.first_child
      @emph = @paragraph.first_child
      @code_inline = @document.last_child.last_child.previous_sibling
    end

    def test_node_can_get_string_content
      assert_equal("HELLO!", @emph.first_child.string_content)
    end

    def test_node_can_set_string_content
      @emph.first_child.string_content = "HOWDY!"

      assert_match(%r{<strong>HOWDY!</strong>}, @document.to_html)
    end

    def test_node_can_protect_against_nodes_without_string_content
      assert_raises(TypeError) do
        @emph.string_content
      end

      assert_raises(TypeError) do
        @emph.string_content = "HOWDY!"
      end

      assert_match(%r{<strong>HELLO!</strong>}, @document.to_html)
    end

    def test_code_inline_can_get_string_content
      assert_equal("nodes", @code_inline.string_content)
    end

    def test_code_inline_can_set_string_content
      @code_inline.string_content = "string content"

      assert_match(%r{<code>string content</code>}, @document.to_html)
    end
  end

  class UrlTest < Minitest::Test
    def setup
      @document = Commonmarker.parse("[GitHub](https://www.github.com)")
      @url_node = @document.first_child.first_child
    end

    def test_node_can_have_url
      assert_equal("https://www.github.com", @url_node.url)
    end

    def test_node_can_set_url
      @url_node.url = "https://www.google.com"

      assert_equal("https://www.google.com", @url_node.url)
      assert_match(%r{<a href="https://www.google.com">GitHub<\/a>}, @document.to_html)
    end
  end

  class TitleTest < Minitest::Test
    def setup
      @document = Commonmarker.parse('![alt text](https://github.com/favicon.ico "Favicon")')
      @title_node = @document.first_child.first_child
    end

    def test_node_can_have_url
      assert_equal("Favicon", @title_node.title)
    end

    def test_node_can_set_url
      @title_node.title = "Google"

      assert_equal("Google", @title_node.title)
      assert_equal("alt text", @title_node.first_child.string_content)
      assert_match(%r{<img src="https:\/\/github.com\/favicon.ico" alt="alt text" title="Google" \/>}, @document.to_html)
    end
  end

  class HeaderTest < Minitest::Test
    def setup
      @document = Commonmarker.parse("### Header Three")
      @header_node = @document.first_child
    end

    def test_has_header_level
      assert_equal(3, @header_node.header_level)
    end

    def test_can_set_a_header_level
      @header_node.header_level = 6

      assert_equal(6, @header_node.header_level)
      assert_match(%r{<h6 id=\"header-three\">Header Three<a href=\"#header-three\" aria-label=\"Link to heading 'Header Three'\" data-heading-content=\"Header Three\" class=\"anchor\"></a></h6>\n}, @document.to_html)
    end
  end

  class ListTypeTest < Minitest::Test
    def setup
      @document = Commonmarker.parse("* Bullet\n* Bullet")
      @list_node = @document.first_child
    end

    def test_has_a_list_type
      assert_equal(:bullet, @list_node.list_type)
    end

    def test_can_set_a_list_type
      @list_node.list_type = :ordered

      assert_equal(:ordered, @list_node.list_type)
      assert_match(%r{<ol>\n<li>Bullet<\/li>\n<li>Bullet<\/li>\n</ol>}, @document.to_html)
    end

    def test_can_prevent_a_malicious_list_type
      @list_node.list_type = :oopsies

      assert_equal(:bullet, @list_node.list_type)
    end
  end

  class ListStartTest < Minitest::Test
    def setup
      @document = Commonmarker.parse("1. One\n2. Two")
      @list_node = @document.first_child
    end

    def test_has_a_list_start
      @list_node.list_start = 1
    end

    def test_can_set_a_list_start
      @list_node.list_start = 3

      assert_equal(3, @list_node.list_start)
      assert_match(%r{<ol start="3">\n<li>One<\/li>\n<li>Two<\/li>\n</ol>}, @document.to_html)
    end
  end

  class ListTightTest < Minitest::Test
    def setup
      @ul_list = Commonmarker.parse("* Bullet\n* Bullet").first_child
      @ol_list = Commonmarker.parse("1. One\n2. Two").first_child
    end

    def test_has_a_list_tight
      assert(@ul_list.list_tight)
      assert(@ol_list.list_tight)
    end

    def test_set_a_list_tight
      @ul_list.list_tight = false
      @ol_list.list_tight = false

      refute(@ul_list.list_tight)
      refute(@ol_list.list_tight)

      assert_match(%r{<ul>\n<li>\n<p>Bullet<\/p>\n</li>\n<li>\n<p>Bullet<\/p>\n</li>\n</ul>}, @ul_list.to_html)
      assert_match(%r{<ol>\n<li>\n<p>One<\/p>\n</li>\n<li>\n<p>Two<\/p>\n</li>\n</ol>}, @ol_list.to_html)
    end
  end

  class FencedTest < Minitest::Test
    def test_fenced_code_block
      document = Commonmarker.parse("```ruby\nputs 'wow'\n```")
      code_block = document.first_child

      assert_predicate(code_block, :fenced?)
    end

    def test_indented_code_block
      document = Commonmarker.parse("    puts 'wow'\n")
      code_block = document.first_child

      refute_predicate(code_block, :fenced?)
    end

    def test_can_set_fenced
      document = Commonmarker.parse("    puts 'wow'\n")
      code_block = document.first_child

      refute_predicate(code_block, :fenced?)

      code_block.fenced = true

      assert_predicate(code_block, :fenced?)
      assert_match(%r{<pre[^>]*><code>.*puts.*wow.*</code></pre>}m, document.to_html)
      assert_match(/```/, document.to_commonmark(options: { render: { prefer_fenced: true } }))
      refute_match(/    /, document.to_commonmark(options: { render: { prefer_fenced: true } }))
    end

    def test_non_code_block_raises
      document = Commonmarker.parse("hello")
      paragraph = document.first_child

      assert_raises(TypeError) { paragraph.fenced? }
    end
  end

  class FenceInfoTest < Minitest::Test
    def setup
      @document = Commonmarker.parse("``` ruby\nputs 'wow'\n```")
      @fence_node = @document.first_child
    end

    def test_has_fence_info
      assert_equal("ruby", @fence_node.fence_info)
    end

    def test_can_set_fence_info
      assert_match(/<pre lang=\"ruby\"/, @document.to_html)

      @fence_node.fence_info = "perl"

      assert_equal("perl", @fence_node.fence_info)
      assert_match(/<pre lang=\"perl\"/, @document.to_html)
    end
  end

  class AlertTypeTest < Minitest::Test
    def test_has_alert_type_for_parsed_alerts
      [:note, :tip, :important, :warning, :caution].each do |type|
        document = Commonmarker.parse("> [!#{type.upcase}]\n> Content", options: { extension: { alerts: true } })

        assert_equal(type, document.first_child.alert_type)
      end
    end

    def test_has_alert_type_for_created_alerts
      [:note, :tip, :important, :warning, :caution].each do |type|
        node = Commonmarker::Node.new(:alert, type: type)

        assert_equal(type, node.alert_type)
      end
    end

    def test_can_set_alert_type
      node = Commonmarker::Node.new(:alert, type: :note)

      node.alert_type = :warning

      assert_equal(:warning, node.alert_type)
      assert_match(/markdown-alert-warning/, node.to_html)
    end

    def test_can_prevent_a_malicious_alert_type
      node = Commonmarker::Node.new(:alert, type: :note)

      node.alert_type = :oopsies

      assert_equal(:note, node.alert_type)
    end

    def test_non_alert_raises
      document = Commonmarker.parse("hello")
      paragraph = document.first_child

      assert_raises(TypeError) { paragraph.alert_type }
      assert_raises(TypeError) { paragraph.alert_type = :note }
    end
  end

  class LiteralTest < Minitest::Test
    def setup
      @document = Commonmarker.parse(<<~MARKDOWN, options: { extension: { front_matter_delimiter: "---", math_dollars: true } })
        ---
        title: front matter
        ---

        Some *text* with `code` and <b>html</b> and $math$.

        ```ruby
        puts 1
        ```

        <div>a block</div>
      MARKDOWN

      @nodes = {}
      @document.walk { |node| @nodes[node.type] ||= node }
    end

    def test_reads_literal_of_text_like_nodes
      assert_equal("Some ", @nodes[:text].literal)
      assert_equal("code", @nodes[:code].literal)
      assert_equal("puts 1\n", @nodes[:code_block].literal)
    end

    def test_reads_literal_of_nodes_without_string_content
      assert_equal("<b>", @nodes[:html_inline].literal)
      assert_equal("<div>a block</div>\n", @nodes[:html_block].literal)
      assert_equal("math", @nodes[:math].literal)
      assert_equal("---\ntitle: front matter\n---\n\n", @nodes[:frontmatter].literal)
    end

    def test_writes_literal_of_raw_markup_nodes
      @nodes[:html_inline].literal = "<i>"
      @nodes[:html_block].literal = "<span>replaced</span>\n"

      html = @document.to_html(options: { render: { unsafe: true } })

      assert_match(%r{<i>html</b>}, html)
      assert_match(%r{<span>replaced</span>}, html)
    end

    def test_writes_literal_of_math_nodes
      @nodes[:math].literal = "y"

      assert_equal("y", @nodes[:math].literal)
      assert_match(/y/, @document.to_html)
    end

    def test_literal_and_string_content_agree_where_both_apply
      [:text, :code, :code_block].each do |type|
        assert_equal(@nodes[type].string_content, @nodes[type].literal, "#{type} disagrees")
      end

      @nodes[:text].literal = "rewritten"

      assert_equal("rewritten", @nodes[:text].string_content)
    end

    def test_raw_node_has_a_literal
      node = Commonmarker::Node.new(:raw, content: "<hr>")

      assert_equal("<hr>", node.literal)

      node.literal = "<br>"

      assert_equal("<br>", node.literal)
    end

    def test_node_without_a_literal_raises
      paragraph = @document.first_child.next_sibling

      assert_raises(TypeError) { paragraph.literal }
      assert_raises(TypeError) { paragraph.literal = "nope" }
    end
  end

  class RespondToTest < Minitest::Test
    TYPE_DEPENDENT_ACCESSORS = {
      string_content: "content",
      literal: "literal",
      url: "https://example.com",
      title: "title",
      header_level: 3,
      list_type: :bullet,
      list_start: 1,
      list_tight: true,
      fence_info: "ruby",
      fenced: true,
      alert_type: :note,
    }.freeze

    def setup
      @document = Commonmarker.parse(<<~MARKDOWN, options: { extension: { front_matter_delimiter: "---", math_dollars: true, alerts: true, table: true, tasklist: true, strikethrough: true, autolink: true, footnotes: true } })
        ---
        title: front matter
        ---

        # Heading

        Some *text* with `code`, <b>html</b>, $math$, a [link](https://example.com),
        an ![image](https://example.com/i.png "Title"), and a footnote[^1].

        - [ ] a task
        - another item

        1. ordered

        > [!NOTE]
        > An alert.

        | a | b |
        |---|---|
        | c | d |

        ```ruby
        puts 1
        ```

            indented code

        <div>a block</div>

        ***

        [^1]: The note.
      MARKDOWN
    end

    def test_reports_false_for_accessors_the_node_type_lacks
      emph = @document.walk.find { |node| node.type == :emph }

      refute_respond_to(emph, :string_content)
      refute_respond_to(emph, :string_content=)
      refute_respond_to(emph, :url)
      refute_respond_to(emph, :header_level)
    end

    def test_reports_true_for_accessors_the_node_type_has
      link = @document.walk.find { |node| node.type == :link }

      assert_respond_to(link, :url)
      assert_respond_to(link, :url=)
      assert_respond_to(link, :title)
    end

    def test_reports_true_for_accessors_that_do_not_depend_on_type
      emph = @document.walk.find { |node| node.type == :emph }

      assert_respond_to(emph, :walk)
      assert_respond_to(emph, :type)
      assert_respond_to(emph, :to_html)
      assert_respond_to(emph, :delete)
      assert_respond_to(emph, :source_position)
    end

    def test_reports_false_for_methods_that_do_not_exist
      refute_respond_to(@document, :nonexistent_method)
    end

    def test_supports_the_walk_and_filter_idiom_from_the_readme
      document = Commonmarker.parse("Hi *there*")

      document.walk do |node|
        node.string_content = "Example" if node.respond_to?(:string_content=)
      end

      assert_equal("<p>Example<em>Example</em></p>\n", document.to_html)
    end

    # Guards against the type lists in `value_supports` drifting away from the
    # match arms in the getters and setters they describe.
    def test_respond_to_agrees_with_whether_the_accessor_raises
      checked = Hash.new(0)

      @document.walk do |node|
        TYPE_DEPENDENT_ACCESSORS.each do |accessor, value|
          reader = accessor == :fenced ? :fenced? : accessor
          writer = :"#{accessor}="

          assert_equal(
            !raises_type_error? { node.public_send(reader) },
            node.respond_to?(reader),
            "#{node.type}##{reader} disagrees with respond_to?",
          )

          assert_equal(
            !raises_type_error? { node.public_send(writer, value) },
            node.respond_to?(writer),
            "#{node.type}##{writer} disagrees with respond_to?",
          )

          checked[node.type] += 1
        end
      end
    end

    private

    def raises_type_error?
      yield
      false
    rescue TypeError
      true
    end
  end
end
