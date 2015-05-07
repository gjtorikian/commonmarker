require 'mkmf'
require 'fileutils'
require 'rbconfig'
host_os = RbConfig::CONFIG['host_os']

CMARK_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'cmark'))
CMARK_BUILD_DIR = File.join(CMARK_DIR, 'build')
FileUtils.rm_rf(CMARK_BUILD_DIR) if File.exist?(CMARK_BUILD_DIR)
FileUtils.mkdir_p(CMARK_BUILD_DIR)

Dir.chdir(CMARK_BUILD_DIR) do
  system 'cmake ..'
  system 'make'
end

$LOCAL_LIBS << "#{CMARK_BUILD_DIR}/src/libcmark.a"

create_makefile('commonmarker/commonmarker')
