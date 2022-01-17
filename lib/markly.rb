#!/usr/bin/env ruby
# frozen_string_literal: true

# The compiled library.
require 'markly/markly'

require_relative 'markly/flags'
require_relative 'markly/node'
require_relative 'markly/renderer/html'

require_relative 'markly/version'

module Markly
  # Public: Parses a Markdown string into a `document` node.
  #
  # string - {String} to be parsed
  # option - A {Symbol} or {Array of Symbol}s indicating the parse options
  # extensions - An {Array of Symbol}s indicating the extensions to use
  #
  # Returns the `parser` node.
  def self.parse(text, flags: DEFAULT, extensions: nil)
    parser = Parser.new(flags)
    
    extensions&.each do |extension|
      parser.enable(extension)
    end
    
    return parser.parse(text.encode(Encoding::UTF_8))
  end
  
  # Public:  Parses a Markdown string into an HTML string.
  #
  # text - A {String} of text
  # option - Either a {Symbol} or {Array of Symbol}s indicating the render options
  # extensions - An {Array of Symbol}s indicating the extensions to use
  #
  # Returns a {String} of converted HTML.
  def self.render_html(text, flags: DEFAULT, parse_flags: flags, render_flags: flags, extensions: [])
    root = self.parse(text, flags: parse_flags, extensions: extensions)
    
    return root.to_html(flags: render_flags, extensions: extensions)
  end
end
