require 'test_helper'

class TestNode < Minitest::Unit::TestCase
  def setup
    @doc = Node.parse_string("Hi *there*")
  end

  def test_walk
    nodes = []
    @doc.walk do |node|
      nodes << node.type
    end
    assert_equal [:document, :paragraph, :text, :emph, :text], nodes
  end

  def test_insert_illegal
    assert_raises NodeError do
      @doc.insert_before(@doc)
    end
  end

  def test_to_html
    assert_equal "<p>Hi <em>there</em></p>\n", @doc.to_html
  end

  def test_html_renderer
    renderer = HtmlRenderer.new
    result = renderer.render(@doc)
    assert_equal "<p>Hi <em>there</em></p>\n", result
  end

  def test_walk_and_set_string_content
    @doc.walk do |node|
      if node.type == :text && node.string_content == 'there'
        node.string_content = 'world'
        assert_equal 'world', node.string_content
      end
    end
  end

  def teardown
    @doc.free
  end
end
