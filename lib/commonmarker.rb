#!/usr/bin/env ruby
require 'commonmarker/commonmarker'
require 'commonmarker/config'
require 'commonmarker/renderer'
require 'commonmarker/renderer/html_renderer'

begin
  require 'awesome_print'
rescue LoadError; end

module CommonMarker
  class Node
    # Parses a string into a :document Node.
    # Params:
    # +s+::  +String+ to be parsed.
    def self.parse_string(s, option = :default)
      Config.option_exists?(option)
      Node.parse_document(s, s.bytesize, Config.to_h[option])
    end

    # Parses a file into a :document Node.
    # Params:
    # +f+::  +File+ to be parsed (caller must open and close).
    def self.parse_file(f)
      s = f.read()
      self.parse_string(s)
    end

    # Iterator over the children (if any) of this Node.
    def each_child
      child = self.first_child
      while child
        nextchild = child.next
        yield child
        child = nextchild
      end
    end

    # An iterator that "walks the tree," descending into children
    # recursively.
    def walk(&blk)
      yield self
      each_child do |child|
        child.walk(&blk)
      end
    end

    # Convert to HTML using libcmark's fast (but uncustomizable) renderer.
    def to_html(option = :default)
      Config.option_exists?(option)
      self._render_html(Config.to_h[option]).force_encoding('utf-8')
    end

  end
end
