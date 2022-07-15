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
  # Public:  Parses a CommonMark string into an HTML string.
  #
  # text - A {String} of text
  # option - Either a {Symbol} or {Array of Symbol}s indicating the render options
  # extensions - An {Array of Symbol}s indicating the extensions to use
  #
  # Returns a {String} of converted HTML.
  def self.render_html(text, options = :DEFAULT, extensions = [])
    raise TypeError, "text must be a String; got a #{text.class}!" unless text.is_a?(String)

    # opts = Config.process_options(options, :render)
    self.commonmark_to_html(text.encode("UTF-8"), 0)
  end
end
