#!/usr/bin/env ruby
require 'commonmarker/commonmarker'
require 'commonmarker/config'
require 'commonmarker/renderer'
require 'commonmarker/renderer/html_renderer'

begin
  require 'awesome_print'
rescue LoadError; end

module CommonMarker
  # Public:  Parses a Markdown string into an HTML string.
  #
  # text - A {String} of text
  # option - Either a {Symbol} or {Array of Symbol}s indicating the parse options.
  #
  # Returns a {String} of converted HTML.
  def self.render_html(text, option = :default)
    Node.markdown_to_html(text, Config.process_options(option))
  end

  # Public: Parses a Markdown string into a `document` node.
  #
  # string - {String} to be parsed.
  # option - A {Symbol} or {Array of Symbol}s indicating the parse options.
  #
  # Returns the `document` node.
  def self.render_doc(s, option = :default)
    Node.parse_document(s, s.bytesize, Config.process_options(option))
  end

  class Node
    # Public: An iterator that "walks the tree," descending into children recursively.
    #
    # blk - A {Proc} representing the action to take for each child.
    def walk(&blk)
      yield self
      each_child do |child|
        child.walk(&blk)
      end
    end

    # Public: Convert the current pointer to HTML.
    #
    # Returns a {String}.
    def to_html(option = :default)
      self._render_html(Config.process_options(option)).force_encoding('utf-8')
    end

    # Internal: Iterate over the children (if any) of the current pointer.
    def each_child
      child = self.first_child
      while child
        nextchild = child.next
        yield child
        child = nextchild
      end
    end
  end
end
