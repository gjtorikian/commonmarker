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

Rake::Task['clean'].enhance do
  ext_dir = File.join(File.dirname(__FILE__), 'ext', 'commonmarker', 'cmark')
  Dir.chdir(ext_dir) do
    `make clean`
  end
end

# Packaging
require 'bundler/gem_tasks'
task :build => [:clean, :compile]

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
task :test => %w(test:unit)

desc 'Run benchmarks'
task :benchmark do |t|
  if ENV['FETCH_PROGIT']
    `rm -rf test/progit`
    `git clone https://github.com/progit/progit.git test/progit`
    langs = %w(ar az be ca cs de en eo es es-ni fa fi fr hi hu id it ja ko mk nl no-nb pl pt-br ro ru sr th tr uk vi zh zh-tw)
    langs.each do |lang|
      `cat test/progit/#{lang}/*/*.markdown >> test/benchinput.md`
    end
  end
  $:.unshift 'lib'
  load 'test/benchmark.rb'
end

desc 'Update tests from git repository'
task :generate_test do
  sh 'python3 ext/commonmarker/cmark/test/spec_tests.py --no-normalize --spec ext/commonmarker/cmark/test/spec.txt --dump-tests > test/spec_tests.json'
end
