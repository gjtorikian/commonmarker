# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "qiita_marker/version"

Gem::Specification.new do |s|
  s.name = "qiita_marker"
  s.version = QiitaMarker::VERSION
  s.summary = "Qiita Marker is a Ruby library for Markdown processing, based on CommonMarker."
  s.description = "A Ruby library that is the core module of the Qiita-specified markdown processor."
  s.authors = ["Qiita Inc."]
  s.homepage = "https://github.com/increments/qiita_marker"
  s.license = "MIT"

  s.files         = ["LICENSE.txt", "README.md", "Rakefile", "qiita_marker.gemspec", "bin/qiita_marker"]
  s.files        += Dir.glob("lib/**/*.rb")
  s.files        += Dir.glob("ext/qiita_marker/*.*")
  s.extensions    = ["ext/qiita_marker/extconf.rb"]

  s.executables = ["qiita_marker"]
  s.require_paths = ["lib", "ext"]
  s.required_ruby_version = [">= 2.6", "< 4.0"]

  s.metadata["rubygems_mfa_required"] = "true"

  s.rdoc_options += ["-x", "ext/qiita_marker/cmark/.*"]

  s.add_development_dependency("awesome_print")
  s.add_development_dependency("json", "~> 2.3")
  s.add_development_dependency("minitest", "~> 5.6")
  s.add_development_dependency("minitest-focus", "~> 1.1")
  s.add_development_dependency("rake")
  s.add_development_dependency("rake-compiler", "~> 0.9")
  s.add_development_dependency("rdoc", "~> 6.2")
  s.add_development_dependency("rubocop")
  s.add_development_dependency("rubocop-standard")
end
