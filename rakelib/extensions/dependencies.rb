# frozen_string_literal: true

require "yaml"
dependencies = YAML.load_file("dependencies.yml")

task gem_build_path do
  ["comrak"].each do |name|
    version = dependencies[name]["version"]

    archive = Dir.glob(File.join("ports", "archives", "#{name}-#{version}.tar.*")).first
    add_file_to_gem(archive)
  end
end
