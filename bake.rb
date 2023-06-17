# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021, by Samuel Williams.

# $LOAD_PATH << ::File.expand_path("ext", __dir__)

def build
	ext_path = File.expand_path("ext/markly", __dir__)
	
	Dir.chdir(ext_path) do
		system("./extconf.rb")
		system("make")
	end
end

def clean
	ext_path = File.expand_path("ext/markly", __dir__)
	
	Dir.chdir(ext_path) do
		system("make clean")
	end
end

def format
	system('clang-format -style llvm -i ext/markly/*.c ext/markly/*.h')
end

def benchmark
  if ENV['FETCH_PROGIT']
    `rm -rf test/progit`
    `git clone https://github.com/progit/progit.git test/progit`
    langs = %w[ar az be ca cs de en eo es es-ni fa fi fr hi hu id it ja ko mk nl no-nb pl pt-br ro ru sr th tr uk vi zh zh-tw]
    langs.each do |lang|
      `cat test/progit/#{lang}/*/*.markdown >> test/benchinput.md`
    end
  end
  $LOAD_PATH.unshift 'lib'
  load 'test/benchmark.rb'
end

def synchronize_upstream
	require 'build/files'
	require 'build/files/system'
	
	root = Build::Files::Path[context.root]
	ext_markly = root/"ext/markly"
	cmark_gfm = root/"cmark-gfm"
	
	(cmark_gfm/"src").glob("**/*").copy(ext_markly)
	(cmark_gfm/"extensions").glob("**/*").copy(ext_markly)
	(cmark_gfm/"build/src").glob("config.h").copy(ext_markly)
	(cmark_gfm/"build/src").glob("cmark-gfm_export.h").copy(ext_markly)
	(cmark_gfm/"build/src").glob("cmark-gfm_version.h").copy(ext_markly)
	(cmark_gfm/"build/extensions").glob("cmark-gfm-extensions_export.h").copy(ext_markly)
end
