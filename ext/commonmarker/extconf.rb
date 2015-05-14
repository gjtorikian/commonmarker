require 'mkmf'
require 'fileutils'
require 'rbconfig'
host_os = RbConfig::CONFIG['host_os']

unless find_executable('cmake')
  $stderr.puts "\n\n\n[ERROR]: cmake is required and not installed. Get it here: http://www.cmake.org/\n\n"
  exit 1
end

CMARK_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'cmark'))
CMARK_BUILD_DIR = File.join(CMARK_DIR, 'build')

# TODO: we need to clear out the build dir that's erroneously getting packaged
# this causes problems, as Linux installation is expecting OS X output
if File.directory?(CMARK_BUILD_DIR) && !File.exist?(ROOT_TMP)
  FileUtils.rm_rf(CMARK_BUILD_DIR)
end
FileUtils.mkdir_p(CMARK_BUILD_DIR)

Dir.chdir(CMARK_BUILD_DIR) do
  system 'cmake ..'
  system 'make'
  # rake-compiler seems to complain about this line, not sure why it's messing with it
  FileUtils.rm_rf(File.join(CMARK_BUILD_DIR, 'Testing', 'Temporary'))
end

$LDFLAGS << " -Wl,-rpath,#{CMARK_BUILD_DIR}/src -L#{CMARK_BUILD_DIR}/src -lcmark"
$CFLAGS << " -I#{CMARK_DIR}/src -I#{CMARK_BUILD_DIR}/src"

create_makefile('commonmarker/commonmarker')
