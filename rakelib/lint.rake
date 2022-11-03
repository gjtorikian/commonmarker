# frozen_string_literal: true

begin
  require "rubocop/rake_task"

  RuboCop::RakeTask.new(:rubocop)
rescue LoadError => e
  warn("WARNING: rubocop is not available in this environment: #{e}")
end
