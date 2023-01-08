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
  spec.license = "MIT"
  spec.homepage = "https://github.com/gjtorikian/commonmarker"

  spec.required_ruby_version = "~> 3.1"
  # https://github.com/rubygems/rubygems/pull/5852#issuecomment-1231118509
  spec.required_rubygems_version = ">= 3.3.22"

  spec.files = ["LICENSE.txt", "README.md", "commonmarker.gemspec", "Cargo.lock"]
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("ext/**/*.{rs,toml,lock,rb}")
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  spec.require_paths = ["lib"]
  spec.extensions = ["ext/commonmarker/Cargo.toml"]

  spec.metadata = {
    "allowed_push_host" => "https://rubygems.org",
    "funding_uri" => "https://github.com/sponsors/gjtorikian/",
    "source_code_uri" => "https://github.com/gjtorikian/commonmarker",
    "rubygems_mfa_required" => "true",
  }

  spec.add_dependency("rb_sys", "~> 0.9")

  spec.add_development_dependency("rake", "~> 13.0")
  spec.add_development_dependency("rake-compiler", "~> 1.2")
  spec.add_development_dependency("rake-compiler-dock", "~> 1.2")
end
