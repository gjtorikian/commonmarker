# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

# require 'markly'
# require 'markly'

require "test_helper"

class NodeTraversalTest < Minitest::Test
  def setup
    @document = Commonmarker.parse("Hi *there*, I am mostly text!")
  end

  def test_it_can_walk_all_nodes
    nodes = []
    @document.walk do |node|
      nodes << node.type
    end

    assert_equal([:document, :paragraph, :text, :emph, :text, :text], nodes)
  end

  def test_enumerate_nodes
    nodes = @document.first_child.map(&:type)

    assert_equal([:text, :emph, :text], nodes)
  end

  def test_select_nodes
    nodes = @document.first_child.select { |node| node.type == :text }

    assert_instance_of(Commonmarker::Node, nodes.first)
    assert_equal([:text, :text], nodes.map(&:type))
  end

  def test_map_nodes
    nodes = @document.first_child.map(&:type)

    assert_equal([:text, :emph, :text], nodes)
  end

  def test_will_not_allow_invalid_node_insertion
    nodes = @document.first_child.map(&:type)

    assert_equal([:text, :emph, :text], nodes)

    @document.insert_before(Commonmarker::Node.new(:document))
    nodes = @document.first_child.map(&:type)

    assert_equal([:text, :emph, :text], nodes)
  end

  def test_generate_html
    assert_equal("<p>Hi <em>there</em>, I am mostly text!</p>\n", @document.to_html)
  end

  def test_walk_and_delete_node
    @document.walk do |node|
      if node.type == :emph
        node.insert_before(node.first_child)
        node.delete
      end
    end

    assert_equal("<p>Hi there, I am mostly text!</p>\n", @document.to_html)
  end

  def test_inspect_node
    assert_includes(@document.inspect, "#<Commonmarker::Node(document)")
  end
end
