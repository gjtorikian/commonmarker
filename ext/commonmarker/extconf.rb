require "mkmf"
require "mini_portile2"

windows = RUBY_PLATFORM =~ /mingw|mswin/
windows_ucrt = RUBY_PLATFORM =~ /(mingw|mswin).*ucrt/
bsd = RUBY_PLATFORM =~ /bsd/
darwin = RUBY_PLATFORM =~ /darwin/
linux = RUBY_PLATFORM =~ /linux/
cross_compiling = ENV['RCD_HOST_RUBY_VERSION'] # set by rake-compiler-dock in build containers
# TruffleRuby uses the Sulong LLVM runtime, which is different from Apple's.
apple_toolchain = darwin && RUBY_ENGINE != 'truffleruby'

GEM_ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
EXT_DIR = File.join(GEM_ROOT_DIR, "ext", "commonmarker")
CROSS_BUILD_P = enable_config("cross-build")

RbConfig::CONFIG["CC"] = RbConfig::MAKEFILE_CONFIG["CC"] = ENV["CC"] if ENV["CC"]
ENV["CC"] = RbConfig::CONFIG["CC"]

def darwin?
  RbConfig::CONFIG["target_os"].include?("darwin")
end

# what follows is pretty much an abuse of miniportile2, but it works for now
# i just need something to download files and run a cargo build; one day this should
# be replaced with actual prepacked binaries.
USER = "kivikakk"
# COMRAK_VERSION = "0.14.0"
COMRAK_VERSION = "c-api-staticlib"
# TARBALL_URL = "https://github.com/#{USER}/comrak/archive/refs/tags/#{COMRAK_VERSION}.tar.gz"
TARBALL_URL = "https://github.com/#{USER}/comrak/archive/refs/heads/#{COMRAK_VERSION}.tar.gz"

MiniPortile.new("comrak", COMRAK_VERSION).tap do |recipe|
  recipe.target = File.join(GEM_ROOT_DIR, "ports")
  recipe.files = [{
    url: TARBALL_URL,
    # sha256: "055fa44ef002a1a07853d3a4dd2a8c553a1dc58ff3809b4fa530ed35694d8571",
  }]

  # configure the environment that MiniPortile will use for subshells
  if CROSS_BUILD_P
    ENV.to_h.tap do |env|
      # -fPIC is necessary for linking into a shared library
      env["CFLAGS"] = [env["CFLAGS"], "-fPIC"].join(" ")

      recipe.configure_options += env.map { |key, value| "#{key}=#{value.strip}" }
    end
  end

  unless File.exist?(File.join(recipe.target, recipe.host, recipe.name, recipe.version))
    recipe.download unless recipe.downloaded?
    recipe.extract

    puts "tmp_path: #{recipe.send(:tmp_path)}"
    system "find ."
    tarball_extract_path = File.join("tmp", recipe.host, "ports", recipe.name, recipe.version, "#{recipe.name}-#{recipe.version}")

    # Why is this so long?
    Dir.chdir(tarball_extract_path) do
      puts `cargo build --manifest-path=./c-api/Cargo.toml --release`
    end
    lib_header_path = File.join(tarball_extract_path, "c-api", "include")
    lib_build_path = File.join(tarball_extract_path, "c-api", "target", "release")

    HEADER_DIRS = [lib_header_path]
    LIB_DIRS = [lib_build_path]

    dir_config('commonmarker', HEADER_DIRS, LIB_DIRS)
  end

  system "find ."
  recipe.activate

  $LIBS << ' -lcomrak_ffi'
end

unless find_header("comrak_ffi.h")
  abort("\nERROR: *** could not find comrak_ffi.h ***\n\n")
end

create_makefile("commonmarker/commonmarker")
