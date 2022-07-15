require "mkmf"
require "mini_portile2"

PACKAGE_ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
EXT_DIR = File.join(PACKAGE_ROOT_DIR, "ext", "commonmarker")
CROSS_BUILD_P = enable_config("cross-build")
COMRAK_VERSION = "0.14.0"

RbConfig::CONFIG["CC"] = RbConfig::MAKEFILE_CONFIG["CC"] = ENV["CC"] if ENV["CC"]
ENV["CC"] = RbConfig::CONFIG["CC"]

def darwin?
  RbConfig::CONFIG["target_os"].include?("darwin")
end

# what follows is pretty miuch an abuse of miniportile2, but it works for now
# i just need something to download files and run a cargo build; one day this should
# be replaced with actual prepacked binaries.
TARBALL_URL = "https://github.com/kivikakk/comrak/archive/refs/tags/#{COMRAK_VERSION}.tar.gz"
MiniPortile.new("comrak", COMRAK_VERSION).tap do |recipe|
  recipe.target = File.join(PACKAGE_ROOT_DIR, "ports")
  recipe.files = [{
    url: TARBALL_URL,
    sha256: "055fa44ef002a1a07853d3a4dd2a8c553a1dc58ff3809b4fa530ed35694d8571",
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

    host = if darwin?
      recipe.host =~ /arm64-apple-darwin(\d+)\.\d+\.0/
      "arm64-darwin#{$1}"
    else
      recipe.host
    end

    # Why is this so long?
    tarball_extract_path = File.join(PACKAGE_ROOT_DIR, "tmp", host, "commonmarker", RUBY_VERSION, "tmp", recipe.host, "ports", recipe.name, recipe.version, "#{recipe.name}-#{recipe.version}")
    Dir.chdir(tarball_extract_path) do
      puts `cargo build --manifest-path=./c-api/Cargo.toml --release`
    end
    lib_header_path = File.join(tarball_extract_path, "c-api", "include")
    lib_build_path = File.join(tarball_extract_path, "c-api", "target", "release")

    HEADER_DIRS = [lib_header_path]
    LIB_DIRS = [lib_build_path]

    dir_config('commonmarker', HEADER_DIRS, LIB_DIRS)
  end

  recipe.activate

  $LIBS << ' -lcomrak_ffi'
end

unless find_header("comrak.h")
  abort("\nERROR: *** could not find comrak.h ***\n\n")
end

create_makefile("commonmarker/commonmarker")
