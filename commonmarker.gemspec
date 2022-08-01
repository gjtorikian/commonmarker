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

  spec.files         = ["LICENSE.txt", "README.md", "Rakefile", "commonmarker.gemspec"]
  spec.files        += Dir.glob("lib/**/*.rb")
  spec.files        += Dir.glob("ext/commonmarker/*.*")
  spec.extensions    = ["ext/commonmarker/extconf.rb"]

  spec.require_paths = ["lib", "ext"]
  spec.required_ruby_version = [">= 3.0", "< 4.0"]

  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_development_dependency("awesome_print")
  spec.add_development_dependency("debug") if "#{RbConfig::CONFIG["MAJOR"]}.#{RbConfig::CONFIG["MINOR"]}".to_f >= 3.1
  spec.add_development_dependency("json", "~> 2.3")
  spec.add_development_dependency("minitest", "~> 5.6")
  spec.add_development_dependency("minitest-focus", "~> 1.1")
  spec.add_development_dependency("nokogiri", "~> 1.13")
  spec.add_development_dependency("rake")
  spec.add_development_dependency("rake-compiler", "~> 0.9")
  spec.add_development_dependency("rdoc", "~> 6.2")
  spec.add_development_dependency("rubocop-standard")

  spec.add_runtime_dependency("mini_portile2", "~> 2.8") # keep version in sync with extconf.rb
end
