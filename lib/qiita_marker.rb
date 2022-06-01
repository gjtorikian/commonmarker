#!/usr/bin/env ruby
# frozen_string_literal: true

require "qiita_marker/qiita_marker"
require "qiita_marker/config"
require "qiita_marker/node"
require "qiita_marker/renderer"
require "qiita_marker/renderer/html_renderer"
require "qiita_marker/version"

begin
  require "awesome_print"
rescue LoadError; end # rubocop:disable Lint/SuppressedException
module QiitaMarker
  # Public:  Parses a Markdown string into an HTML string.
  #
  # text - A {String} of text
  # option - Either a {Symbol} or {Array of Symbol}s indicating the render options
  # extensions - An {Array of Symbol}s indicating the extensions to use
  #
  # Returns a {String} of converted HTML.
  def self.render_html(text, options = :DEFAULT, extensions = [])
    raise TypeError, "text must be a String; got a #{text.class}!" unless text.is_a?(String)

    opts = Config.process_options(options, :render)
    Node.markdown_to_html(text.encode("UTF-8"), opts, extensions)
  end

  # Public: Parses a Markdown string into a `document` node.
  #
  # string - {String} to be parsed
  # option - A {Symbol} or {Array of Symbol}s indicating the parse options
  # extensions - An {Array of Symbol}s indicating the extensions to use
  #
  # Returns the `document` node.
  def self.render_doc(text, options = :DEFAULT, extensions = [])
    raise TypeError, "text must be a String; got a #{text.class}!" unless text.is_a?(String)

    opts = Config.process_options(options, :parse)
    text = text.encode("UTF-8")
    Node.parse_document(text, text.bytesize, opts, extensions)
  end
end
