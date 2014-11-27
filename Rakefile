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
  sh 'python test/spec_tests.py --spec test/spec.txt --prog bin/commonmarker' do
    # ignore errors
  end
  sh 'python test/spec_tests.py --spec test/spec.txt --prog "bin/commonmarker --html-renderer"' do
    # ignore errors
  end
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
  sh 'cp -v commonmark.tmp/spec.txt commonmark.tmp/spec_tests.py test/'
  sh 'rm -rf commonmark.tmp'
end
