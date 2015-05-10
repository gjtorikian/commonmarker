require 'mkmf'
require 'fileutils'
require 'rbconfig'
host_os = RbConfig::CONFIG['host_os']

if host_os =~ /darwin|mac os/
  ext = 'a'
else
  ext = 'so'
end

CMARK_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'cmark'))
CMARK_BUILD_DIR = File.join(CMARK_DIR, 'build')
FileUtils.mkdir_p(CMARK_BUILD_DIR)

Dir.chdir(CMARK_BUILD_DIR) do
  system 'cmake ..'
  system 'make'
end

$CFLAGS << " -I#{CMARK_DIR}/src -I#{CMARK_BUILD_DIR}/src"
$LOCAL_LIBS << "#{CMARK_BUILD_DIR}/src/libcmark.#{ext}"

create_makefile('commonmarker/commonmarker')
