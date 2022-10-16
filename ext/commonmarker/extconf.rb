require "mkmf"

require_relative "_util"
require_relative "_config"
require_relative "_help"

GEM_ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))

if debug?
  puts "Compiling in debug mode (using Ruby #{RUBY_VERSION})..."

  require "debug"
  require "awesome_print"

  append_cflags("-Wextra")
  append_cflags("-fno-omit-frame-pointer")
  append_cflags("-fno-optimize-sibling-calls")
  CONFIG["debugflags"] = "-ggdb -g"
  CONFIG["optflags"] = "-O0"
end

static_linking = config_static?
puts "Static linking is #{static_linking ? "enabled" : "disabled"}."

cross_build_p = config_cross_build?
puts "Cross build is #{cross_build_p ? "enabled" : "disabled"}."

require_relative "_cflags"

RbConfig::CONFIG["CC"] = RbConfig::MAKEFILE_CONFIG["CC"] = ENV.fetch("CC", nil) if ENV["CC"]

# use same c compiler
ENV["CC"] = RbConfig::CONFIG["CC"]

require_relative "_comrak"
COMRAK_RECIPE = build_comrak

lib_header_path = File.join(COMRAK_RECIPE.path, "include")
lib_build_path = File.join(COMRAK_RECIPE.path, "release")

HEADER_DIRS = [lib_header_path]
LIB_DIRS = [lib_build_path]

if uncertain_linux?
  # FIXME: does not appear to work
elsif config_static?
  $LIBS << ' -l:libcomrak_ffi.a'
else
  $LIBS << ' -lcomrak_ffi'
end

if !windows?
  if config_static?
    $libs << " #{File.join(lib_build_path, "libcomrak_ffi.#{$LIBEXT}")}"
  end

  $LDFLAGS += " -L#{lib_build_path}/libcomrak_ffi.a"

  $LIBPATH = ["#{COMRAK_RECIPE.path}/release"] | $LIBPATH
  pkg_config('comrak_ffi')

else
  append_cppflags("-I#{lib_header_path}")

  if config_static?
    $libs << ' -lcomrak_ffi'
    $LDFLAGS += " -L#{lib_build_path}"
  end

  $LIBPATH = [lib_build_path] | $LIBPATH
  pkg_config('comrak_ffi')
end


# xref: https://github.com/sparklemotion/nokogiri/blob/fe9cc9893463a660477e25820b53f19518c286b7/ext/nokogiri/extconf.rb#L982
if config_cross_build?
  # When precompiling native gems, copy packaged libraries' headers to ext/commonmarker/include
  # These are packaged up by the cross-compiling callback in the ExtensionTask
  copy_packaged_libraries_headers(COMRAK_RECIPE.path, File.join(GEM_ROOT_DIR, "ext/commonmarker/include"))
else
  # When compiling during installation, install packaged libraries' header files into ext/commonmarker/include
  copy_packaged_libraries_headers(COMRAK_RECIPE.extracted_ffi_path, File.join(GEM_ROOT_DIR, "ext/commonmarker/include"))
  $INSTALLFILES << ["ext/commonmarker/include/**/*.h", "$(rubylibdir)"]
end

dir_config('commonmarker', HEADER_DIRS, LIB_DIRS)

if uncertain_linux?
  # FIXME: does not appear to work
else
  unless find_header("comrak_ffi.h", HEADER_DIRS)
    abort("\nERROR: *** could not find comrak_ffi.h ***\n\n")
  end
end

create_makefile("commonmarker/commonmarker")
