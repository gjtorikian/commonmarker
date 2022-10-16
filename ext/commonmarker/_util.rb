# frozen_string_literal: true

RUBY_MAJOR, RUBY_MINOR = RUBY_VERSION.split(".").collect(&:to_i)

PACKAGE_ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
PACKAGE_EXT_DIR = File.join(PACKAGE_ROOT_DIR, "ext", "selma")

REQUIRED_MINI_PORTILE_VERSION = "~> 2.8.0" # keep this version in sync with the one in the gemspec

OS = case os = RbConfig::CONFIG["host_os"].downcase
when /linux/
  # The official ruby-alpine Docker containers pre-build Ruby. As a result,
  #   Ruby doesn't know that it's on a musl-based platform. `ldd` is the
  #   only reliable way to detect musl that we've found.
  # See https://github.com/skylightio/skylight-ruby/issues/92
  if ENV["SKYLIGHT_MUSL"] || %x(ldd --version 2>&1).include?("musl")
    "linux-musl"
  else
    "linux"
  end
when /darwin/
  "darwin"
when /freebsd/
  "freebsd"
when /netbsd/
  "netbsd"
when /openbsd/
  "openbsd"
when /sunos|solaris/
  "solaris"
when /mingw|mswin/
  "windows"
else
  os
end

# Normalize the platform CPU
ARCH = case cpu = RbConfig::CONFIG["host_cpu"].downcase
when /amd64|x86_64|x64/
  "x86_64"
when /i?86|x86|i86pc/
  "x86"
when /ppc|powerpc/
  "powerpc"
when /^aarch/
  "aarch"
when /^arm/
  "arm"
else
  cpu
end

def windows?
  OS == "windows"
end

def solaris?
  OS == solaries
end

def darwin?
  OS == "darwin"
end

def macos?
  darwin? || OS == "macos"
end

def openbsd?
  OS == "openbsd"
end

def aix?
  OS == "aix"
end

def nix?
  !(windows? || solaris? || darwin?)
end

def x86_64?
  ARCH == "x86_64"
end

def x86?
  ARCH == "x86"
end

def chdir_for_build(&block)
  # When using rake-compiler-dock on Windows, the underlying Virtualbox shared
  # folders don't support symlinks.
  # Work around this limitation by using the temp dir for cooking.
  build_dir = /mingw|mswin|cygwin/.match?(ENV["RCD_HOST_RUBY_PLATFORM"].to_s) ? "/tmp" : "."
  Dir.chdir(build_dir, &block)
end

def abs_path(path)
  File.join(PACKAGE_EXT_DIR, path)
end

def copy_packaged_library_headers(to_path:, from:)
  FileUtils.mkdir_p(to_path)
  from.each do |header_loc|
    FileUtils.cp_r(Dir[File.join(header_loc, "*.h")], to_path)
  end
end

def copy_packaged_binaries(bin_loc, to_path:)
  FileUtils.mkdir_p(to_path)
  FileUtils.cp(bin_loc, to_path)
end

def find_header_or_abort(header, *paths)
  find_header(header, *paths) || abort("lol_html.h was expected in `#{paths.join(", ")}`, but it is missing.")
end

def find_library_or_abort(lib, func, *paths)
  find_library(lib, func, *paths) || abort("#{lib} was expected in `#{paths.join(", ")}`, but it is missing.")
end

def concat_flags(*args)
  args.compact.join(" ")
end

def copy_packaged_libraries_headers(from_path, to_path)
  FileUtils.rm_rf(to_path, secure: true)
  FileUtils.mkdir(to_path)
  FileUtils.cp_r(Dir[File.join(from_path, "include/*")], to_path)
end

def uncertain_linux?
  ["arm", "aarch"].include?(ARCH) && OS == "linux"
end
