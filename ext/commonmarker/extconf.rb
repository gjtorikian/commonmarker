require 'mkmf'
require 'fileutils'
require 'rbconfig'
host_os = RbConfig::CONFIG['host_os']
sitearch = RbConfig::CONFIG['sitearch']

LIBDIR      = RbConfig::CONFIG['libdir']
INCLUDEDIR  = RbConfig::CONFIG['includedir']

ROOT_TMP = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'tmp'))
CMARK_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'cmark'))

#Dir.chdir(CMARK_BUILD_DIR) do
  #system "make libcmark-gfm_static" or abort "make libcmark-gfm_static failed"
  #system "make libcmark-gfmextensions_static" or abort "make libcmark-gfmextensions_static failed"
  # rake-compiler seems to complain about this line, not sure why it's messing with it
  #FileUtils.rm_rf(File.join(CMARK_BUILD_DIR, 'Testing', 'Temporary'))
#end

HEADER_DIRS = [INCLUDEDIR]
LIB_DIRS = [LIBDIR] #, "#{CMARK_BUILD_DIR}/src", "#{CMARK_BUILD_DIR}/extensions"]

dir_config('cmark', HEADER_DIRS, LIB_DIRS)

# don't even bother to do this check if using OS X's messed up system Ruby: http://git.io/vsxkn
unless sitearch =~ /^universal-darwin/
  #abort 'libcmark-gfm is missing.' unless find_library('cmark-gfm', 'cmark_parse_document')
  #abort 'libcmark-gfmextensions is missing.' unless find_library('cmark-gfmextensions', 'core_extensions_ensure_registered')
end

#$LDFLAGS << " -L#{CMARK_BUILD_DIR}/src -L#{CMARK_BUILD_DIR}/extensions -lcmark-gfm -lcmark-gfmextensions"
$CFLAGS << " -O2 -I#{CMARK_DIR}/src -I#{CMARK_DIR}/extensions " #-I#{CMARK_BUILD_DIR}/src -I#{CMARK_BUILD_DIR}/extensions"
$CFLAGS << " -DCMARK_STATIC_DEFINE -DCMARKEXTENSIONS_STATIC_DEFINE"

$srcs = ['commonmarker.c', *Dir['cmark/src/*.c'], *Dir['cmark/src/*.h']]
create_makefile('commonmarker/commonmarker')
