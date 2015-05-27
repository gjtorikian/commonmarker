require 'mkmf'
require 'fileutils'
require 'rbconfig'
host_os = RbConfig::CONFIG['host_os']

LIBDIR      = RbConfig::CONFIG['libdir']
INCLUDEDIR  = RbConfig::CONFIG['includedir']

unless find_executable('cmake')
  $stderr.puts "\n\n\n[ERROR]: cmake is required and not installed. Get it here: http://www.cmake.org/\n\n"
  exit 1
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
  system 'cmake .. -DCMAKE_C_FLAGS=-fPIC'
  system 'make libcmark_static'
  # rake-compiler seems to complain about this line, not sure why it's messing with it
  FileUtils.rm_rf(File.join(CMARK_BUILD_DIR, 'Testing', 'Temporary'))
end

HEADER_DIRS = [INCLUDEDIR]
LIB_DIRS = [LIBDIR, "#{CMARK_BUILD_DIR}/src"]

dir_config('cmark', HEADER_DIRS, LIB_DIRS)

unless find_library('cmark', 'cmark_parse_document')
  abort 'libcmark is missing.'
end

$LDFLAGS << " -L#{CMARK_BUILD_DIR}/src -lcmark"
$CFLAGS << " -O2 -I#{CMARK_DIR}/src -I#{CMARK_BUILD_DIR}/src"

create_makefile('commonmarker/commonmarker')
