require 'date'
require 'rake/clean'
require 'rake/extensiontask'
require 'digest/md5'

task :default => [:test]

# Gem Spec
gem_spec = Gem::Specification.load('commonmarker.gemspec')

# Ruby Extension
Rake::ExtensionTask.new('commonmarker', gem_spec) do |ext|
  ext.lib_dir = File.join('lib', 'commonmarker')
end

# Packaging
require 'bundler/gem_tasks'

# Testing
require 'rake/testtask'

Rake::TestTask.new('test:unit') do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/test_*.rb'
  t.verbose = true
  t.warning = false
end

task 'test:unit' => :compile

desc 'Run unit and conformance tests'
task :test => %w[test:unit]

desc 'Run benchmarks'
task :benchmark => :compile do |t|
  $:.unshift 'lib'
  load 'test/benchmark.rb'
end

desc 'Update tests from git repository'
task :gather do
  sh 'python3 ext/commonmarker/cmark/test/spec_tests.py --spec ext/commonmarker/cmark/test/spec.txt --dump-tests > test/spec_tests.json'
end
