# frozen_string_literal: true

require_relative 'node/inspect'

module Markly
  class Node
    include Enumerable
    include Inspect

    # Public: An iterator that "walks the tree," descending into children recursively.
    #
    # blk - A {Proc} representing the action to take for each child
    def walk(&block)
      return enum_for(:walk) unless block_given?

      yield self
      each do |child|
        child.walk(&block)
      end
    end

    # Public: Convert the node to an HTML string.
    #
    # options - A {Symbol} or {Array of Symbol}s indicating the render options
    # extensions - An {Array of Symbol}s indicating the extensions to use
    #
    # Returns a {String}.
    def to_html(flags: DEFAULT, extensions: [])
      _render_html(flags, extensions).force_encoding('utf-8')
    end

    # Public: Convert the node to a CommonMark string.
    #
    # options - A {Symbol} or {Array of Symbol}s indicating the render options
    # width - Column to wrap the output at
    #
    # Returns a {String}.
    def to_commonmark(flags: DEFAULT, width: 120)
      _render_commonmark(flags, width).force_encoding('utf-8')
    end

    alias to_markdown to_commonmark

    # Public: Convert the node to a plain text string.
    #
    # options - A {Symbol} or {Array of Symbol}s indicating the render options
    # width - Column to wrap the output at
    #
    # Returns a {String}.
    def to_plaintext(flags: DEFAULT, width: 120)
      _render_plaintext(flags, width).force_encoding('utf-8')
    end

    # Public: Iterate over the children (if any) of the current pointer.
    def each
      return enum_for(:each) unless block_given?

      child = first_child
      while child
        nextchild = child.next
        yield child
        child = nextchild
      end
    end

    # Deprecated: Please use `each` instead
    def each_child(&block)
      warn '[DEPRECATION] `each_child` is deprecated.  Please use `each` instead.'
      each(&block)
    end
  end
end
