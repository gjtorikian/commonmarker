# frozen_string_literal: true

require_relative "commonmarker/extension"

require "commonmarker/config"
require "commonmarker/renderer"
require "commonmarker/version"

if ENV.fetch("DEBUG", false)
  require "awesome_print"
  require "debug"
end

module Commonmarker
  class << self
    # Public: Parses a CommonMark string into an HTML string.
    #
    # text - A {String} of text
    # option - A {Hash} of render, parse, and extension options to transform the text.
    #
    # Returns a {String} of converted HTML.
    def to_html(text, options: Commonmarker::Config::OPTS)
      raise TypeError, "text must be a String; got a #{text.class}!" unless text.is_a?(String)
      raise TypeError, "text must be UTF-8 encoded; got #{text.encoding}!" unless text.encoding.name == "UTF-8"
      raise TypeError, "options must be a Hash; got a #{options.class}!" unless options.is_a?(Hash)

      opts = Config.process_options(options)
      commonmark_to_html(text, opts)
    end
  end
end
