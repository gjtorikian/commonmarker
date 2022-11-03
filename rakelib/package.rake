# frozen_string_literal: true

require "rubygems/package_task"
Gem::PackageTask.new(COMMONMARKER_SPEC).define

desc "Build packages for every supported platform"
task "native:packages" => CROSS_PLATFORMS.map { |platform| "gem:#{platform}" }
