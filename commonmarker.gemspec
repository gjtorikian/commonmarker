# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'commonmarker/version'
Gem::Specification.new do |s|
  s.name = 'commonmarker'
  s.version = CommonMarker::VERSION
  s.summary = "CommonMark parser and renderer"
  s.description = "A fast, safe, extensible parser for CommonMark"
  s.date = '2014-11-25'
  s.email = 'jgm@berkeley.edu'
  s.homepage = 'http://github.com/jgm/commonmarker'
  s.authors = ["John MacFarlane"]
  s.license = 'BSD3'
  s.required_ruby_version = '>= 1.9.2'
  # = MANIFEST =
  s.files         = %w(LICENSE README.md Rakefile commonmarker.gemspec Gemfile bin/commonmarker)
  s.files        += Dir.glob('lib/**/*.rb')
  s.files        += Dir.glob('ext/**/*')
  s.test_files    = Dir.glob('test/**/*')
  s.extensions    = ['ext/commonmarker/extconf.rb']
  # = MANIFEST =
  s.test_files = s.files.grep(%r{^test/})
  s.extra_rdoc_files = ["LICENSE"]
  s.executables = ["commonmarker"]
  s.require_paths = %w(lib ext)

  s.add_dependency   'ruby-enum', '~> 0.4'
  s.add_development_dependency "rake-compiler", "~> 0.9"
  s.add_development_dependency "bundler", "~> 1.9"
  s.add_development_dependency "json", "~> 1.8.1"
end
