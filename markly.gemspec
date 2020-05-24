
require_relative "lib/markly/version"

Gem::Specification.new do |spec|
	spec.name = "markly"
	spec.version = Markly::VERSION
	
	spec.summary = "CommonMark parser and renderer. Written in C, wrapped in Ruby."
	spec.authors = ["Garen Torikian", "Ashe Connor", "Samuel Williams"]
	spec.license = "MIT"
	
	spec.homepage = "https://github.com/ioquatix/markly"
	
	spec.metadata = {
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
	}
	
	spec.files = Dir['{bin,ext,lib}/**/*', base: __dir__]
	
	spec.executables = ["markly"]
	
	spec.extensions = ["ext/markly/extconf.rb"]
	
	spec.required_ruby_version = ">= 2.5"
	
	spec.add_development_dependency "bake"
	spec.add_development_dependency "bake-bundler"
	spec.add_development_dependency "bake-modernize"
	spec.add_development_dependency "minitest", "~> 5.6"
	spec.add_development_dependency "rake"
	spec.add_development_dependency "rake-compiler", "~> 0.9"
end
