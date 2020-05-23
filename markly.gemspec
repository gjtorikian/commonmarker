
require_relative 'lib/markly/version'

Gem::Specification.new do |s|
  s.name = 'markly'
  s.version = Markly::VERSION
  s.summary = 'CommonMark parser and renderer. Written in C, wrapped in Ruby.'
  s.description = 'A fast, safe, extensible parser for CommonMark. This wraps the official libcmark-gfm library.'
  s.authors = ['Garen Torikian', 'Ashe Connor', 'Samuel Williams']
  s.homepage = 'https://github.com/ioquatix/markly'
  s.license = 'MIT'

  s.files         = %w[bin/markly]
  s.files        += Dir.glob('lib/**/*.rb')
  s.files        += Dir.glob('ext/markly/*.*')
  s.extensions    = ['ext/markly/extconf.rb']

  s.executables = ['markly']
  s.require_paths = %w[lib ext]

  s.rdoc_options += ['-x', 'ext/markly/cmark/.*']

  s.add_dependency 'ruby-enum', '~> 0.5'

  s.add_development_dependency 'awesome_print'
  s.add_development_dependency 'json', '~> 1.8'
  s.add_development_dependency 'minitest', '~> 5.6'
  s.add_development_dependency 'minitest-focus', '~> 1.1'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rake-compiler', '~> 0.9'
  s.add_development_dependency 'rdoc', '~> 6.2'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-standard'
  s.add_development_dependency 'bake'
  s.add_development_dependency 'bake-bundler'
  s.add_development_dependency 'bake-modernize'
end
