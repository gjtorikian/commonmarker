# frozen_string_literal: true

require "commonmarker/node/ast"
require "commonmarker/node/inspect"

module Commonmarker
  class Node
    include Enumerable
    include Inspect

    # Public: An iterator that "walks the tree," descending into children recursively.
    #
    # blk - A {Proc} representing the action to take for each child
    def walk(&block)
      return enum_for(:walk) unless block

      yield self
      each do |child|
        child.walk(&block)
      end
    end

    # Public: Iterate over the children (if any) of the current pointer.
    def each
      return enum_for(:each) unless block_given?

      child = first_child
      while child
        next_child = child.next_sibling
        yield child
        child = next_child
      end
    end

    # Public: Converts a node to an HTML string.
    #
    # options - A {Hash} of render, parse, and extension options to transform the text.
    # plugins - A {Hash} of additional plugins.
    #
    # Returns a {String} of HTML.
    def to_html(options: {}, plugins: {})
      raise TypeError, "options must be a Hash; got a #{options.class}!" unless options.is_a?(Hash)

      node_to_html(options: options, plugins: plugins)
    end

    # Public: Convert the node to a CommonMark string.
    #
    # options - A {Hash} of render, parse, and extension options.
    # plugins - A {Hash} of additional plugins.
    #
    # Returns a {String}.
    def to_commonmark(options: {}, plugins: {})
      raise TypeError, "options must be a Hash; got a #{options.class}!" unless options.is_a?(Hash)

      node_to_commonmark(options: options, plugins: plugins)
    end
  end
end
