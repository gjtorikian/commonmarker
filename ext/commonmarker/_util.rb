# frozen_string_literal: true

RUBY_MAJOR, RUBY_MINOR = RUBY_VERSION.split(".").collect(&:to_i)

PACKAGE_ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
PACKAGE_EXT_DIR = File.join(PACKAGE_ROOT_DIR, "ext", "commonmarker")

OS = case os = RbConfig::CONFIG["host_os"].downcase
when /linux/
  # The official ruby-alpine Docker containers pre-build Ruby. As a result,
  # Ruby doesn't know that it's on a musl-based platform. `ldd` is the
  # a more reliable way to detect musl.
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

def abs_path(path)
  File.join(PACKAGE_EXT_DIR, path)
end

def find_header_or_abort(header, *paths)
  find_header(header, *paths) || abort("#{header} was expected in `#{paths.join(", ")}`, but it is missing.")
end

def find_library_or_abort(lib, func, *paths)
  find_library(lib, func, *paths) || abort("#{lib} was expected in `#{paths.join(", ")}`, but it is missing.")
end

def concat_flags(*args)
  args.compact.join(" ")
end

