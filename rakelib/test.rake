# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new("test") do |t|
  t.libs << "lib"
  t.libs << "test"
  t.pattern = "test/**/parser_test.rb"
  t.verbose = true
  t.warning = false
end
