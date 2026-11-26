# frozen_string_literal: true

require_relative "commonmarker/extension"

require "commonmarker/errors"
require "commonmarker/node"
require "commonmarker/renderer"
require "commonmarker/version"

class Commonmarker
  class << self
    # Public: Parses a CommonMark string into an AST.
    #
    # text - A {String} of text
    # options - A {Hash} of render, parse, and extension options to transform the text.
    #
    # The options are processed on every call. To parse many documents with the
    # same options, create an instance with `Commonmarker.new` and call `parse`
    # on it instead.
    #
    # Returns the `document` node.
    def parse(text, options: {})
      new(options: options).parse(text)
    end

    # Public: Parses a CommonMark string into an HTML string.
    #
    # text - A {String} of text
    # options - A {Hash} of render, parse, and extension options to transform the text.
    # plugins - A {Hash} of additional plugins.
    #
    # The options and plugins are processed on every call. To convert many
    # documents with the same configuration, create an instance with
    # `Commonmarker.new` and call `to_html` on it instead.
    #
    # Returns a {String} of converted HTML.
    def to_html(text, options: {}, plugins: {})
      new(options: options, plugins: plugins).to_html(text)
    end
  end

  # Public: Creates a converter with a fixed set of options and plugins.
  #
  # options - A {Hash} of render, parse, and extension options to transform the text.
  # plugins - A {Hash} of additional plugins.
  #
  # The options and plugins are validated and processed once, here, so each
  # later `parse`, `to_html`, or `to_commonmark` call skips that work. Changing
  # the hashes after this point has no effect on the instance. Instances hold
  # no mutable state and can be shared across threads.
  def initialize(options: {}, plugins: {})
    raise TypeError, "options must be a Hash; got a #{options.class}!" unless options.is_a?(Hash)

    commonmark_init(options, plugins)
  end

  # Public: Parses a CommonMark string into an AST using this instance's options.
  #
  # text - A {String} of text
  #
  # Returns the `document` node.
  def parse(text)
    check_text(text)

    commonmark_parse(text)
  end

  # Public: Converts CommonMark into HTML using this instance's options and plugins.
  #
  # input - A {String} of CommonMark, or a {Commonmarker::Node} to render as-is
  #         (for example, a document from `parse` that you have since modified).
  #
  # Returns a {String} of converted HTML.
  def to_html(input)
    return commonmark_render_html(input) if input.is_a?(Node)

    check_text(input, or_node: true)

    commonmark_to_html(input)
  end

  # Public: Converts CommonMark into CommonMark using this instance's options
  # and plugins. Given a {String}, this parses and re-emits it; given a
  # {Commonmarker::Node}, it writes out that node.
  #
  # input - A {String} of CommonMark, or a {Commonmarker::Node}.
  #
  # Returns a {String} of CommonMark.
  def to_commonmark(input)
    return commonmark_render_commonmark(input) if input.is_a?(Node)

    check_text(input, or_node: true)

    commonmark_to_commonmark(input)
  end

  private

  def check_text(text, or_node: false)
    unless text.is_a?(String)
      accepted = or_node ? "a String or a Commonmarker::Node" : "a String"
      raise TypeError, "text must be #{accepted}; got a #{text.class}!"
    end

    raise TypeError, "text must be UTF-8 encoded; got #{text.encoding}!" unless text.encoding.name == "UTF-8"
  end
end
