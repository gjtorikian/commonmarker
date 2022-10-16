# frozen_string_literal: true

require "rbconfig"
require "rake_compiler_dock"

require "rake_compiler_dock"

require_relative "extensions/util"
require_relative "extensions/cross_rubies"

ENV["RUBY_CC_VERSION"] = CROSS_RUBIES.map(&:ver).uniq.join(":")

def install_additional_packages_for(cr)
  if cr.darwin?
    [
      "curl https://sh.rustup.rs -sSf > rustup.sh",
      "bash rustup.sh -y; PATH=\"$HOME/.cargo/bin:${PATH}\"",
      "cargo --version",
    ].join(" && ")
  elsif cr.linux?
    [
      "sudo apt-get update -y",
      "sudo apt-get install -y cargo",
    ].join(" && ")
  end
end

namespace "gem" do
  CROSS_RUBIES.find_all { |cr| cr.windows? || cr.linux? || cr.darwin? }.map(&:platform).uniq.each do |platform|
    cr = CROSS_RUBIES.find { |cr| cr.platform == platform }

    desc "build native gem for #{platform} platform"
    task platform do
      puts "Invoking RakeCompilerDock for #{platform} ..."
      RakeCompilerDock.sh(<<~EOT, platform: platform, verbose: true)
        #{install_additional_packages_for(cr)}
        rvm use 3.1.0 &&
        gem install bundler --no-document &&
        bundle &&
        bundle exec rake gem:#{platform}:builder MAKE='nice make -j`nproc`'
      EOT
    end

    namespace platform do
      desc "build native gem for #{platform} platform (guest container)"
      task "builder" do
        puts "Invoking native:#{platform} ..."
        # use Task#invoke because the pkg/*gem task is defined at runtime
        Rake::Task["native:#{platform}"].invoke
        puts "Invoking #{"pkg/#{COMMONMARKER_SPEC.full_name}-#{Gem::Platform.new(platform)}.gem"}  ..."

        Rake::Task["pkg/#{COMMONMARKER_SPEC.full_name}-#{Gem::Platform.new(platform)}.gem"].invoke
      end
    end
  end

  desc "build native gems for windows"
  multitask "windows" => CROSS_RUBIES.find_all(&:windows?).map(&:platform).uniq

  desc "build native gems for linux"
  multitask "linux" => CROSS_RUBIES.find_all(&:linux?).map(&:platform).uniq

  desc "build native gems for darwin"
  multitask "darwin" => CROSS_RUBIES.find_all(&:darwin?).map(&:platform).uniq
end

require "rake/extensiontask"

# FIXME: remove this hack if multiple versions of Ruby are supported...
module Rake
  class ExtensionTask < BaseExtensionTask
    def define_cross_platform_tasks(for_platform)
      ruby_vers = ENV["RUBY_CC_VERSION"].split(":")

      old_multi = ruby_vers.size > 1 ? true : false
      multi = true
      puts "DEBUG: multi = #{multi} (was: #{old_multi})"
      ruby_vers.each do |version|
        # save original lib_dir
        orig_lib_dir = @lib_dir

        # tweak lib directory only when targeting multiple versions
        if multi
          version =~ /(\d+\.\d+)/
          @lib_dir = "#{@lib_dir}/#{::Regexp.last_match(1)}"
        end

        define_cross_platform_tasks_with_version(for_platform, version)

        # restore lib_dir
        @lib_dir = orig_lib_dir
      end
    end
  end
end

require_relative "extensions/dependencies"

Rake::ExtensionTask.new("commonmarker", COMMONMARKER_SPEC.dup) do |ext|
  ext.source_pattern = "*.{c,h}"

  lib_dir = File.join(*["lib", "commonmarker", ENV["FAT_DIR"]].compact)
  ext.lib_dir = lib_dir
  ext.config_options << ENV["EXTOPTS"]
  ext.cross_compile = true
  ext.cross_platform = CROSS_RUBIES.map(&:platform).uniq
  ext.cross_config_options << "--enable-cross-build" # so extconf.rb knows we're cross-compiling
  ext.cross_compiling do |spec|
    # remove things not needed for precompiled gems
    spec.files.reject! { |path| File.fnmatch?("ports/*", path) }
    spec.files.reject! { |file| File.fnmatch?("*.tar.gz", file) }
    spec.files.reject! { |file| File.fnmatch?("*.bundle", file) }
    spec.dependencies.reject! { |dep| dep.name == "mini_portile2" }

    # when pre-compiling a native gem, package all the C headers sitting in ext/commonmarker/include
    # which were copied there in the $INSTALLFILES section of extconf.rb.
    # (see script/test-gem-file-contents and script/test-gem-installation for tests)
    headers_dir = "ext/commonmarker/include"

    Dir.glob(File.join(headers_dir, "**", "*.h")).each do |header|
      spec.files << header
    end

    # FIXME: remove this hack if multiple versions of Ruby are supported...
    is_darwin = spec.platform.os == "darwin"
    extension = is_darwin ? "bundle" : "so"
    spec.files << "lib/commonmarker/3.1/commonmarker.#{extension}"
  end
end
