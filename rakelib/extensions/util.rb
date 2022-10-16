# frozen_string_literal: true

def gem_build_path
  File.join("pkg", COMMONMARKER_SPEC.full_name)
end

def add_file_to_gem(relative_source_path)
  if relative_source_path.nil? || !File.exist?(relative_source_path)
    raise "Cannot find file '#{relative_source_path}'"
  end

  dest_path = File.join(gem_build_path, relative_source_path)
  dest_dir = File.dirname(dest_path)

  puts "Adding #{relative_source_path} to gem"

  mkdir_p(dest_dir) unless Dir.exist?(dest_dir)
  rm_f(dest_path) if File.exist?(dest_path)
  safe_ln(relative_source_path, dest_path)

  COMMONMARKER_SPEC.files << relative_source_path
end
