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

def update_cmark_gfm
	# echo "Checking out cmark-gfm"
	# echo "---------------------"
	# cd cmark-gfm
	# git fetch origin
	# git checkout $BRANCH && git pull
	# sha=`git rev-parse HEAD`
	# cd ../../..
	# make
	# cp cmark-gfm/extensions/*.{c,h} ext/markly
	# cp cmark-gfm/src/*.{inc,c,h} ext/markly
	# rm ext/markly/main.c
	# git add cmark-gfm
	# git add ext/markly/
	# git commit -m "Update cmark-gfm to $(git config submodule.cmark-gfm.url | sed s_.git\$__)/commit/${sha}"
end
