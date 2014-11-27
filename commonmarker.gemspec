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
    ext/commonmarker/CMakeLists.txt
    ext/commonmarker/commonmarker.h
    ext/commonmarker/commonmarker.c
    ext/commonmarker/bench.h
    ext/commonmarker/blocks.c
    ext/commonmarker/buffer.c
    ext/commonmarker/buffer.h
    ext/commonmarker/case_fold_switch.inc
    ext/commonmarker/chunk.h
    ext/commonmarker/cmark.c
    ext/commonmarker/cmark.h
    ext/commonmarker/config.h.in
    ext/commonmarker/debug.h
    ext/commonmarker/config.h
    ext/commonmarker/cmark_export.h
    ext/commonmarker/extconf.rb
    ext/commonmarker/html
    ext/commonmarker/inlines.c
    ext/commonmarker/inlines.h
    ext/commonmarker/main.c
    ext/commonmarker/node.c
    ext/commonmarker/node.h
    ext/commonmarker/parser.h
    ext/commonmarker/print.c
    ext/commonmarker/references.c
    ext/commonmarker/references.h
    ext/commonmarker/scanners.c
    ext/commonmarker/scanners.h
    ext/commonmarker/scanners.re
    ext/commonmarker/utf8.c
    ext/commonmarker/utf8.h
    ext/commonmarker/html/houdini.h
    ext/commonmarker/html/houdini_href_e.c
    ext/commonmarker/html/houdini_html_e.c
    ext/commonmarker/html/houdini_html_u.c
    ext/commonmarker/html/html.c
    ext/commonmarker/html/html_unescape.gperf
    ext/commonmarker/html/html_unescape.h
  ]
  # = MANIFEST =
  s.test_files = s.files.grep(%r{^test/})
  s.extra_rdoc_files = ["LICENSE"]
  s.extensions = ["ext/commonmarker/extconf.rb"]
  s.executables = ["commonmarker"]
  s.require_paths = ["lib"]

  s.add_runtime_dependency "ffi", "~> 1.9.0"

  s.add_development_dependency "rake-compiler", "~> 0.8.3"
  s.add_development_dependency "bundler", "~> 1.7.7"
end
