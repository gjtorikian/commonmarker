# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "commonmarker/version"

Gem::Specification.new do |spec|
  spec.name = "commonmarker"
  spec.version = Commonmarker::VERSION
  spec.summary = "CommonMark parser and renderer. Written in Rust, wrapped in Ruby."
  spec.description = "A fast, safe, extensible parser for CommonMark. This wraps the comrak Rust crate."
  spec.authors = ["Garen Torikian", "Ashe Connor"]
  spec.homepage = "https://github.com/gjtorikian/commonmarker"
  spec.license = "MIT"

  spec.files = [
    "Gemfile",
    "LICENSE.txt",
    "README.md",
    "dependencies.yml",
    "ext/commonmarker/commonmarker.h",
    "ext/commonmarker/commonmarker.c",
  ]
  spec.files += Dir.glob("lib/**/*.rb")
  spec.extensions << "ext/commonmarker/extconf.rb"

  spec.required_ruby_version = [">= 3.1", "< 4.0"]

  spec.metadata = {
    "funding_uri" => "https://github.com/sponsors/gjtorikian/",
    "rubygems_mfa_required" => "true",
  }

  spec.add_development_dependency("rake", "~> 13.0")
  spec.add_development_dependency("rake-compiler", "~> 1.0")
  spec.add_development_dependency("rake-compiler-dock", "~> 1.2")
  spec.add_development_dependency("rdoc", "~> 6.2")

  spec.add_runtime_dependency("mini_portile2", "~> 2.8") # keep version in sync with extconf.rb
end
