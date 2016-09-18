require 'mkmf'
require 'fileutils'
require 'rbconfig'
host_os = RbConfig::CONFIG['host_os']
sitearch = RbConfig::CONFIG['sitearch']

LIBDIR      = RbConfig::CONFIG['libdir']
INCLUDEDIR  = RbConfig::CONFIG['includedir']

unless find_executable('cmake')
  abort "\n\n\n[ERROR]: cmake is required and not installed. Get it here: http://www.cmake.org/\n\n\n"
end

ROOT_TMP = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'tmp'))
CMARK_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'cmark'))
CMARK_BUILD_DIR = File.join(CMARK_DIR, 'build')

# TODO: we need to clear out the build dir that's erroneously getting packaged
# this causes problems, as Linux installation is expecting OS X output
if File.directory?(CMARK_BUILD_DIR) && !File.exist?(ROOT_TMP)
  FileUtils.rm_rf(CMARK_BUILD_DIR)
end
FileUtils.mkdir_p(CMARK_BUILD_DIR)

Dir.chdir(CMARK_BUILD_DIR) do
  if host_os == 'mingw32'
    system 'cmake .. -G "MSYS Makefiles"'
  else
    system 'cmake .. -DCMAKE_C_FLAGS=-fPIC'
  end
  system "make libcmark_static" or abort "make libcmark_static failed"
  system "make libcmarkextensions_static" or abort "make libcmarkextensions_static failed"
  # rake-compiler seems to complain about this line, not sure why it's messing with it
  FileUtils.rm_rf(File.join(CMARK_BUILD_DIR, 'Testing', 'Temporary'))
end

HEADER_DIRS = [INCLUDEDIR]
LIB_DIRS = [LIBDIR, "#{CMARK_BUILD_DIR}/src", "#{CMARK_BUILD_DIR}/extensions"]

dir_config('cmark', HEADER_DIRS, LIB_DIRS)

# don't even bother to do this check if using OS X's messed up system Ruby: http://git.io/vsxkn
unless sitearch =~ /^universal-darwin/
  abort 'libcmark is missing.' unless find_library('cmark', 'cmark_parse_document')
  abort 'cmarkextensions is missing.' unless find_library('cmarkextensions', 'core_extensions_registration')
end

$LDFLAGS << " -L#{CMARK_BUILD_DIR}/src -L#{CMARK_BUILD_DIR}/extensions -lcmark -lcmarkextensions"
$CFLAGS << " -O2 -I#{CMARK_DIR}/src -I#{CMARK_DIR}/extensions -I#{CMARK_BUILD_DIR}/src"
$CFLAGS << " -DCMARK_STATIC_DEFINE"

create_makefile('commonmarker/commonmarker')
