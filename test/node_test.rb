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

    assert_match(/~bazinga~\*there\*/, @document.to_commonmark)
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
      assert_match(%r{<h6><a href=\"#header-three\" aria-hidden=\"true\" class=\"anchor\" id=\"header-three\"></a>Header Three</h6>\n}, @document.to_html)
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

  class FenceInfoTest < Minitest::Test
    def setup
      @document = Commonmarker.parse("``` ruby\nputs 'wow'\n```")
      @fence_node = @document.first_child
    end

    def test_has_fence_info
      assert_equal("ruby", @fence_node.fence_info)
    end

    def test_can_set_fence_info
      @fence_node.fence_info = "perl"

      assert_equal("perl", @fence_node.fence_info)
      assert_match(%r{<pre lang="perl"><code>puts 'wow'\n<\/code><\/pre>}, @document.to_html)
    end
  end
end
