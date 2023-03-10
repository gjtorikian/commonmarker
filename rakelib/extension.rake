# frozen_string_literal: true

require "rb_sys/extensiontask"

RbSys::ExtensionTask.new("commonmarker", COMMONMARKER_SPEC) do |ext|
  ext.lib_dir = File.join("lib", "commonmarker")
end

desc "Build native extension for a given platform (i.e. `rake 'native[x86_64-linux]'`)"
task :native, [:platform] do |_t, platform:|
  sh "bundle", "exec", "rb-sys-dock", "--platform", platform, "--build"
end

desc "Compile and build native extension for a given platform (i.e. `rake 'native[x86_64-linux]'`)"
task build: :compile
