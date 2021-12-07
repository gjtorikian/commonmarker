# frozen_string_literal: true

require('fileutils')

namespace :qiita_marker do
  desc 'Rename commonmarker to qiita_marker'
  task :rename_project do
    ProjectRenamer.rename
  end

  desc 'Move submodules of ext/commonmarker to ext/qiita_marker'
  task :move_submodules do
    sh 'rm -fr ext/qiita_marker/cmark-upstream'
    sh 'git mv ext/commonmarker/cmark-upstream ext/qiita_marker/cmark-upstream'
  end

  desc 'Format clang files of qfm'
  task :format_qfm do
    paths = Dir.glob('ext/qiita_marker/qfm*.{c,h,re}')
    sh "clang-format -style llvm -i #{paths.join(' ')}"
  end

  desc 'Run re2c'
  task :re2c do
    Dir.glob('ext/qiita_marker/qfm_*.re').each do |path|
      c_filename = path.sub(/\.re$/, '.c')
      sh "re2c --case-insensitive -b -i --no-debug-info --no-generation-date -8 --encoding-policy substitute -o #{c_filename} #{path}"
      sh "clang-format -style llvm -i #{c_filename} #{path}"
    end
  end

  desc 'Clean generated files by re2c'
  task :re2c_clean do
    Dir.glob('ext/qiita_marker/qfm_*.re').each do |path|
      c_filename = path.sub(/\.re$/, '.c')
      sh "test -e #{c_filename} && rm -f #{c_filename} || true"
    end
  end
end

module ProjectRenamer
  PATH_MAP = {
    'commonmarker' => 'qiita_marker'
  }.freeze

  SYMBOL_MAP = {
    'commonmarker' => 'qiita_marker',
    'CommonMarker' => 'QiitaMarker',
    'COMMONMARKER' => 'QIITA_MARKER'
  }.freeze

  SYMBOL_RENAME_EXCLUSION_PATH_PATTERNS = [
    /\.(?:bundle|so)$/,
    /README/,
    %r{^ext/commonmarker/cmark-upstream/},
    %r{^tasks/},
    %r{^tmp/}
  ].freeze

  class << self
    def rename
      rename_paths
      rename_symbols
    end

    private

    def rename_paths
      Dir.glob('**/*').each do |path|
        next if SYMBOL_RENAME_EXCLUSION_PATH_PATTERNS.any? { |pattern| path.match?(pattern) }

        PATH_MAP.each do |old, new|
          next unless path.include?(old)

          if File.directory?(path)
            FileUtils.mkdir_p(path.gsub(old, new))
          else
            File.rename(path, path.gsub(old, new))
          end
        end
      end
    end

    def rename_symbols
      Dir.glob('**/*').each do |path|
        next if SYMBOL_RENAME_EXCLUSION_PATH_PATTERNS.any? { |pattern| path.match?(pattern) }
        next unless File.file?(path)

        source = File.read(path)

        SYMBOL_MAP.each do |old, new|
          source.gsub!(old, new)
        end

        File.write(path, source)
      end
    end
  end
end
