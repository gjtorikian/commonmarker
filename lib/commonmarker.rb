# frozen_string_literal: true

require_relative "commonmarker/extension"

require "commonmarker/node"
require "commonmarker/renderer"
require "commonmarker/version"

module Commonmarker
  class << self
    # Public: Parses a CommonMark string into an AST.
    #
    # text - A {String} of text
    # options - A {Hash} of render, parse, and extension options to transform the text.
    #
    # Returns the `parser` node.
    def parse(text, options: {})
      raise TypeError, "text must be a String; got a #{text.class}!" unless text.is_a?(String)
      raise TypeError, "text must be UTF-8 encoded; got #{text.encoding}!" unless text.encoding.name == "UTF-8"
      raise TypeError, "options must be a Hash; got a #{options.class}!" unless options.is_a?(Hash)

      commonmark_parse(text, options: options)
    end

    # Public: Parses a CommonMark string into an HTML string.
    #
    # text - A {String} of text
    # options - A {Hash} of render, parse, and extension options to transform the text.
    # plugins - A {Hash} of additional plugins.
    #
    # Returns a {String} of converted HTML.
    def to_html(text, options: {}, plugins: {})
      raise TypeError, "text must be a String; got a #{text.class}!" unless text.is_a?(String)
      raise TypeError, "text must be UTF-8 encoded; got #{text.encoding}!" unless text.encoding.name == "UTF-8"
      raise TypeError, "options must be a Hash; got a #{options.class}!" unless options.is_a?(Hash)

      commonmark_to_html(text, options: options, plugins: plugins)
    end
  end
end
