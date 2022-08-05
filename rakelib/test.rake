# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new("test:unit") do |t|
  t.libs << "lib"
  t.libs << "test"
  t.pattern = "test/test_*.rb"
  t.verbose = true
  t.warning = false
end

desc "Run unit tests"
task "test:unit" => :compile

desc "Run unit and conformance tests"
task test: ["test:unit"]
