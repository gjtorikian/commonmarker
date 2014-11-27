require 'date'
require 'rake/clean'
require 'rake/extensiontask'
require 'digest/md5'

task :default => [:test]

# Gem Spec
gem_spec = Gem::Specification.load('commonmarker.gemspec')

# Ruby Extension
Rake::ExtensionTask.new('commonmarker', gem_spec)

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
task :test => %w[test:unit test:spec]

desc 'Run spec tests'
task 'test:spec' => :compile do |t|
  # eventually do something with test/spec_tests.json
end

desc 'Run benchmarks'
task :benchmark => :compile do |t|
  $:.unshift 'lib'
  load 'test/benchmark.rb'
end

desc 'Update cmark sources from git repository'
task :gather do
  sh 'git clone https://github.com/jgm/CommonMark commonmark.tmp'
  sh 'cp -rv commonmark.tmp/src/* commonmark.tmp/src/*.* ext/commonmarker/'
  sh 'python commonmark.tmp/spec_tests.py --spec commonmark.tmp/spec.txt --dump-tests > test/spec_tests.json'
  sh 'rm -rf commonmark.tmp'
end
