# frozen_string_literal: true

require "rubocop/rake_task"

RuboCop::RakeTask.new(:rubocop)

desc "Match C style of cmark"
task :format do
  sh "clang-format -style llvm -i ext/commonmarker/*.c ext/commonmarker/*.h"
end
