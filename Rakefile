# frozen_string_literal: true

# Gem Spec
require "bundler/gem_tasks"
COMMONMARKER_SPEC = Bundler.load_gemspec("commonmarker.gemspec")

# Packaging
require "rubygems/package_task"
gem_path = Gem::PackageTask.new(COMMONMARKER_SPEC).define
desc "Package the Ruby gem"
task "package" => [gem_path]
