#!/usr/bin/env ruby
require 'commonmarker/commonmarker'
require 'commonmarker/config'
require 'commonmarker/renderer'
require 'commonmarker/renderer/html_renderer'
require 'commonmarker/version'

begin
  require 'awesome_print'
rescue LoadError; end

module CommonMarker
  # Public:  Parses a Markdown string into an HTML string.
  #
  # text - A {String} of text
  # option - Either a {Symbol} or {Array of Symbol}s indicating the parse options
  #
  # Returns a {String} of converted HTML.
  def self.render_html(text, options = :default)
    fail TypeError, 'text must be a string!' unless text.is_a?(String)
    opts = Config.process_options(options, :render)
    text = text.encode('UTF-8')
    html = Node.markdown_to_html(text, opts)
    html.force_encoding('UTF-8')
  end

  # Public: Parses a Markdown string into a `document` node.
  #
  # string - {String} to be parsed
  # option - A {Symbol} or {Array of Symbol}s indicating the parse options
  #
  # Returns the `document` node.
  def self.render_doc(text, options = :default)
    fail TypeError, 'text must be a string!' unless text.is_a?(String)
    opts = Config.process_options(options, :render)
    text = text.encode('UTF-8')
    Node.parse_document(text, text.bytesize, opts)
  end

  class Node
    # Public: An iterator that "walks the tree," descending into children recursively.
    #
    # blk - A {Proc} representing the action to take for each child
    def walk(&blk)
      yield self
      each_child do |child|
        child.walk(&blk)
      end
    end

    # Public: Convert the node to an HTML string.
    #
    # Returns a {String}.
    def to_html(options = :default)
      opts = Config.process_options(options, :render)
      _render_html(opts).force_encoding('utf-8')
    end

    # Internal: Iterate over the children (if any) of the current pointer.
    def each_child
      child = first_child
      while child
        nextchild = child.next
        yield child
        child = nextchild
      end
    end
  end
end
