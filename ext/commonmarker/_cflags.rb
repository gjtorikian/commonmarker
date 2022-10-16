# frozen_string_literal: true

# adopt environment config
append_cflags(ENV["CFLAGS"].split) unless ENV["CFLAGS"].nil?
append_cppflags(ENV["CPPFLAGS"].split) unless ENV["CPPFLAGS"].nil?
append_ldflags(ENV["LDFLAGS"].split) unless ENV["LDFLAGS"].nil?
$LIBS = concat_flags($LIBS, ENV.fetch("LIBS", nil)) # rubocop:disable Style/GlobalVars

append_cflags(["-std=c11", "-Wno-declaration-after-statement"])

# always include debugging information
append_cflags("-g")

# good to have no matter what Ruby was compiled with
append_cflags("-Wmissing-noreturn")

# handle clang variations, see nokogiri#1101
append_cflags("-Wno-error=unused-command-line-argument-hard-error-in-future") if darwin?

append_cflags("-Werror=incompatible-pointer-types")

append_cflags(ci? || debug? ? "-O0" : "-O2")

# Work around a character escaping bug in MSYS by passing an arbitrary double-quoted parameter to gcc.
# See https://sourceforge.net/p/mingw/bugs/2142
append_cppflags(' "-Idummypath"') if windows?

if openbsd?
  unless /clang/.match?(%x(#{ENV.fetch("CC", "/usr/bin/cc")} -v 2>&1))
    (ENV["CC"] ||= find_executable("egcc")) ||
      abort("Please install gcc 4.9+ from ports using `pkg_add -v gcc`")
  end
  append_cppflags("-I/usr/local/include")
end
