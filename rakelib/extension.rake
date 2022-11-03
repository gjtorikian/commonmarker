# frozen_string_literal: true

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

require_relative "extension/cross_rubies"

Rake::ExtensionTask.new("commonmarker", COMMONMARKER_SPEC) do |ext|
  ext.source_pattern = "*.{rs,toml}"

  ext.lib_dir = File.join("lib", "commonmarker")

  ext.cross_compile = true
  ext.cross_platform = CROSS_PLATFORMS

  ext.config_script = ENV["ALTERNATE_CONFIG_SCRIPT"] || "extconf.rb"

  # remove things not needed for precompiled gems
  ext.cross_compiling do |spec|
    spec.files.reject! { |file| File.fnmatch?("*.tar.gz", file) }
    spec.dependencies.reject! { |dep| dep.name == "rb-sys" }
  end
end

task :setup do # rubocop:disable Rake/Desc
  require "rake_compiler_dock"
  RakeCompilerDock.sh(<<~EOT, verbose: true)
    gem update --system 3.3.22 --no-document &&
    bundle
  EOT
rescue => e
  warn(e.message)
end

namespace "gem" do
  CROSS_RUBIES.find_all { |cr| cr.windows? || cr.linux? || cr.darwin? }.map(&:platform).uniq.each do |platform|
    desc "build native gem for #{platform} platform"
    task platform do
      puts "Invoking RakeCompilerDock for #{platform} ..."
      require "rake_compiler_dock"
      RakeCompilerDock.sh(<<~EOT, verbose: true)
        gem update --system 3.3.22 --no-document &&
        bundle
      EOT
    rescue => e
      warn(e.message)
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
