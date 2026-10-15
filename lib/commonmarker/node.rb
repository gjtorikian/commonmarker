# frozen_string_literal: true

require "commonmarker/node/ast"
require "commonmarker/node/inspect"

module Commonmarker
  class Node
    include Enumerable
    include Inspect

    # Public: Whether this node responds to the given method.
    #
    # name        - A {Symbol} or {String} naming the method.
    # include_all - A {Boolean} indicating whether to consider private methods.
    #
    # Returns a {Boolean}.
    def respond_to?(name, include_all = false)
      return false if node_supports?(name.to_sym) == false

      super
    end

    # Public: An iterator that "walks the tree," yielding each node and then
    # its descendants, in document order.
    #
    # The walk is iterative rather than recursive, so arbitrarily deep trees
    # can't exhaust the stack.
    #
    # blk - A {Proc} representing the action to take for each node
    def walk(&block)
      return enum_for(:walk) unless block

      yield self

      # Like #each, the next sibling is captured before a node is yielded, so
      # the block may detach or replace the node it is given. `pending` holds
      # the sibling to resume at once each ancestor's subtree is done.
      pending = []
      node = first_child
      while node
        next_node = node.next_sibling
        yield node
        pending << next_node if next_node
        node = node.first_child || pending.pop
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
    def to_html(options: Commonmarker::Config::OPTIONS, plugins: Commonmarker::Config::PLUGINS)
      raise TypeError, "options must be a Hash; got a #{options.class}!" unless options.is_a?(Hash)

      opts = Config.process_options(options)
      plugins = Config.process_plugins(plugins)

      node_to_html(render: opts[:render], parse: opts[:parse], extension: opts[:extension], plugins: plugins).force_encoding("utf-8")
    end

    # Public: Convert the node to a CommonMark string.
    #
    # options - A {Symbol} or {Array of Symbol}s indicating the render options
    # plugins - A {Hash} of additional plugins.
    #
    # Returns a {String}.
    def to_commonmark(options: Commonmarker::Config::OPTIONS, plugins: Commonmarker::Config::PLUGINS)
      raise TypeError, "options must be a Hash; got a #{options.class}!" unless options.is_a?(Hash)

      opts = Config.process_options(options)
      plugins = Config.process_plugins(plugins)

      node_to_commonmark(render: opts[:render], parse: opts[:parse], extension: opts[:extension], plugins: plugins).force_encoding("utf-8")
    end
  end
end
