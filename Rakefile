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

desc 'Match C style of cmark'
task :format do
  sh 'clang-format -style llvm -i ext/commonmarker/*.c ext/commonmarker/*.h'
end

# Documentation
require 'rdoc/task'

desc 'Generate API documentation'
RDoc::Task.new do |rd|
  rd.rdoc_dir = 'docs'
  rd.main     = 'README.md'
  rd.rdoc_files.include 'README.md', 'lib/**/*.rb', 'ext/commonmarker/commonmarker.c'

  rd.options << '--markup tomdoc'
  rd.options << '--inline-source'
  rd.options << '--line-numbers'
  rd.options << '--all'
  rd.options << '--fileboxes'
end

desc "Generate and publish docs to gh-pages"
task :publish => [:rdoc] do
  Dir.mktmpdir do |tmp|
    system "mv docs/* #{tmp}"
    system "git checkout gh-pages"
    system "rm -rf *"
    system "mv #{tmp}/* ."
    message = "Site updated at #{Time.now.utc}"
    system "git add ."
    system "git commit -am #{message.shellescape}"
    system "git push origin gh-pages --force"
    system "git checkout master"
    system "echo yolo"
  end
end
