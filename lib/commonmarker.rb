#!/usr/bin/env ruby
# frozen_string_literal: true

begin
  # load the precompiled extension file
  ruby_version = /(\d+\.\d+)/.match(::RUBY_VERSION)
  require_relative "commonmarker/#{ruby_version}/commonmarker"
rescue LoadError
  # fall back to the extension compiled upon installation.
  require "commonmarker/commonmarker"
end

require "commonmarker/config"
require "commonmarker/renderer"
require "commonmarker/version"

if ENV.fetch("DEBUG", false)
  require "awesome_print"
  require "debug"
end

module Commonmarker
  # Public: Parses a CommonMark string into an HTML string.
  #
  # text - A {String} of text
  # option - A {Hash} of render, parse, and extension options to transform the text.
  #
  # Returns a {String} of converted HTML.
  def self.to_html(text, options: Commonmarker::Config::OPTS)
    raise TypeError, "text must be a String; got a #{text.class}!" unless text.is_a?(String)
    raise TypeError, "options must be a Hash; got a #{options.class}!" unless options.is_a?(Hash)

    opts = Config.process_options(options)
    commonmark_to_html(text.encode("UTF-8"), opts)
  end
end
