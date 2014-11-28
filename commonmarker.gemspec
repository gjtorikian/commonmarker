# encoding: utf-8
Gem::Specification.new do |s|
  s.name = 'commonmarker'
  s.version = '0.1'
  s.summary = "CommonMark parser and renderer"
  s.description = "A fast, safe, extensible parser for CommonMark"
  s.date = '2014-11-25'
  s.email = 'jgm@berkeley.edu'
  s.homepage = 'http://github.com/jgm/commonmarker'
  s.authors = ["John MacFarlane"]
  s.license = 'BSD3'
  s.required_ruby_version = '>= 1.9.2'
  # = MANIFEST =
  s.files = %w[
    LICENSE
    Gemfile
    README.md
    Rakefile
    commonmarker.gemspec
    bin/commonmarker
    lib/commonmarker.rb
    test/benchmark.rb
    test/test_basics.rb
    test/test_pathological_inputs.rb
  ]
  # = MANIFEST =
  s.test_files = s.files.grep(%r{^test/})
  s.extra_rdoc_files = ["LICENSE"]
  s.executables = ["commonmarker"]
  s.require_paths = ["lib"]

  s.add_runtime_dependency "ffi", "~> 1.9.0"

  s.add_development_dependency "rake-compiler", "~> 0.8.3"
  s.add_development_dependency "bundler", "~> 1.7.7"
  s.add_development_dependency "json", "~> 1.8.1"
end
