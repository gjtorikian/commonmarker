# frozen_string_literal: true

require "rake/clean"
require "rake/extensiontask"

CROSS_RUBIES = ["3.1.0", "3.0.0", "2.7.0"]
CROSS_PLATFORMS = [
  "x64-mingw32",
  "x64-mingw-ucrt",
  "x86-linux",
  "x86_64-linux",
  "aarch64-linux",
  "x86_64-darwin",
  "arm64-darwin",
]
ENV["RUBY_CC_VERSION"] = CROSS_RUBIES.join(":")

Rake::ExtensionTask.new("commonmarker", COMMONMARKER_SPEC) do |ext|
  ext.lib_dir = File.join("lib", "commonmarker")
  ext.cross_compile = true
  ext.cross_platform = CROSS_PLATFORMS
  ext.cross_config_options << "--enable-cross-build" # so extconf.rb knows we're cross-compiling
  ext.cross_compiling do |spec|
    # remove things not needed for precompiled gems
    spec.dependencies.reject! { |dep| dep.name == "mini_portile2" }
    spec.files.reject! { |file| File.fnmatch?("*.tar.gz", file) }
  end
end

namespace "gem" do
  CROSS_PLATFORMS.each do |platform|
    desc "build native gem for #{platform}"
    task platform do
      RakeCompilerDock.sh(<<~EOF, platform: platform)
        gem install bundler --no-document &&
        bundle &&
        bundle exec rake gem:#{platform}:buildit
      EOF
    end

    namespace platform do
      # this runs in the rake-compiler-dock docker container
      task "buildit" do
        # use Task#invoke because the pkg/*gem task is defined at runtime
        Rake::Task["native:#{platform}"].invoke
        Rake::Task["pkg/#{COMMONMARKER_SPEC.full_name}-#{Gem::Platform.new(platform)}.gem"].invoke
      end
    end
  end
end
