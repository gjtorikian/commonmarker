# frozen_string_literal: true

require_relative "lib/markly/version"

Gem::Specification.new do |spec|
	spec.name = "markly"
	spec.version = Markly::VERSION
	
	spec.summary = "CommonMark parser and renderer. Written in C, wrapped in Ruby."
	spec.authors = ["Garen Torikian", "Yuki Izumi", "Samuel Williams", "John MacFarlane", "Garen J. Torikian", "Ashe Connor", "Nick Wellnhofer", "digitalMoksha", "Andrew Anderson", "Ben Woosley", "Tomoya Chiba", "Akira Matsuda", "FUJI Goro", "FUJI Goro (gfx)", "Jerry van Leeuwen", "Michael Camilleri", "Mu-An ✌️ Chiou", "Olle Jonsson", "Roberto Hidalgo", "Vitaliy Klachkov", "diachini"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/ioquatix/markly"
	
	spec.metadata = {
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
	}
	
	spec.files = Dir.glob(['{ext,lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	spec.require_paths = ['lib']
	
	spec.executables = ["markly"]
	
	spec.extensions = ["ext/markly/extconf.rb"]
	
	spec.required_ruby_version = ">= 2.5"
	
	spec.add_development_dependency "bake"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "sus"
end
