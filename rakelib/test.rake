# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new("test") do |t|
  t.libs << "lib"
  t.libs << "test"
  t.pattern = "test/test_*.rb"
  t.verbose = true
  t.warning = false
end
