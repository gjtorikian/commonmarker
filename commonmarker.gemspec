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
    test/bench.rb
    test/test.rb
    ext/cmark/CMakeLists.txt
    ext/cmark/bench.h
    ext/cmark/blocks.c
    ext/cmark/buffer.c
    ext/cmark/buffer.h
    ext/cmark/case_fold_switch.inc
    ext/cmark/chunk.h
    ext/cmark/cmark.c
    ext/cmark/cmark.h
    ext/cmark/config.h.in
    ext/cmark/debug.h
    ext/cmark/config.h
    ext/cmark/cmark_export.h
    ext/cmark/extconf.rb
    ext/cmark/html
    ext/cmark/inlines.c
    ext/cmark/inlines.h
    ext/cmark/main.c
    ext/cmark/node.c
    ext/cmark/node.h
    ext/cmark/parser.h
    ext/cmark/print.c
    ext/cmark/references.c
    ext/cmark/references.h
    ext/cmark/scanners.c
    ext/cmark/scanners.h
    ext/cmark/scanners.re
    ext/cmark/utf8.c
    ext/cmark/utf8.h
    ext/cmark/html/houdini.h
    ext/cmark/html/houdini_href_e.c
    ext/cmark/html/houdini_html_e.c
    ext/cmark/html/houdini_html_u.c
    ext/cmark/html/html.c
    ext/cmark/html/html_unescape.gperf
    ext/cmark/html/html_unescape.h
  ]
  # = MANIFEST =
  s.test_files = s.files.grep(%r{^test/})
  s.extra_rdoc_files = ["LICENSE"]
  s.extensions = ["ext/cmark/extconf.rb"]
  s.executables = ["commonmarker"]
  s.require_paths = ["lib"]

  s.add_development_dependency "rake-compiler", "~> 0.8.3"
end
