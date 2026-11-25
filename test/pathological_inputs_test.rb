# frozen_string_literal: true

require "test_helper"
require "minitest/benchmark"

# Inputs that have historically triggered pathological (quadratic or worse)
# behavior in CommonMark parsers, after cmark's test/pathological_tests.py.
# They nest or repeat far past the default `max_nesting_depth`, which is lifted
# here because the point is that parsing stays fast and correct regardless.
module PathologicalInputs
  OPTIONS = { parse: { max_nesting_depth: 1_000_000 } }.freeze

  # name => [input, pattern the rendered HTML must match]
  CASES = {
    "nested strong emph" => [
      "#{"*a **a " * 65_000}b#{" a** a*" * 65_000}",
      /(<em>a <strong>a ){65000}b( a<\/strong> a<\/em>){65000}/,
    ],
    "many emph closers with no openers" => [
      "a_ " * 65_000,
      /(a[_] ){64999}a_/,
    ],
    "many emph openers with no closers" => [
      "_a " * 65_000,
      /(_a ){64999}_a/,
    ],
    "many link closers with no openers" => [
      "a]" * 65_000,
      /(a\]){65000}/,
    ],
    "many link openers with no closers" => [
      "[a" * 65_000,
      /(\[a){65000}/,
    ],
    "mismatched openers and closers" => [
      "*a_ " * 50_000,
      /([*]a[_] ){49999}[*]a_/,
    ],
    "link openers and emph closers" => [
      "[ a_" * 50_000,
      /(\[ a_){50000}/,
    ],
    "hard link/emph case" => [
      "**x [a*b**c*](d)",
      %r{\*\*x <a href="d">a<em>b\*\*c</em></a>},
    ],
    "nested brackets" => [
      "#{"[" * 50_000}a#{"]" * 50_000}",
      /\[{50000}a\]{50000}/,
    ],
    "nested block quotes" => [
      "#{"> " * 50_000}a",
      /(<blockquote>\n){50000}/,
    ],
    "U+0000 in input" => [
      "abc\u0000de\u0000",
      /abc�?de�?/,
    ],
  }.freeze

  class << self
    def markdown(str)
      Commonmarker.to_html(str, options: OPTIONS)
    end
  end
end

class PathologicalInputsTest < Minitest::Test
  # The whole set renders in well under a second on a laptop; a quadratic
  # regression at these sizes takes minutes. This fails fast instead of
  # hanging CI.
  TIME_LIMIT_SECONDS = 10

  PathologicalInputs::CASES.each do |name, (input, expected)|
    define_method(:"test_#{name.tr("^a-z0-9", "_")}") do
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      html = PathologicalInputs.markdown(input)
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

      assert_match(expected, html)
      assert_operator(elapsed, :<, TIME_LIMIT_SECONDS, "#{name} took #{elapsed.round(2)}s")

      # The same document through the Ruby-visible tree, which copies every
      # node in and out of comrak (see GHSA-c4fj-h48v-9fxp).
      assert_equal(html, Commonmarker.parse(input, options: PathologicalInputs::OPTIONS).to_html)
    end
  end
end

# Scaling checks: each input must grow linearly with its size. They are
# timing-based and therefore noisy, so they only run on request:
#
#   BENCH=1 bundle exec rake test TEST=test/pathological_inputs_test.rb
class PathologicalInputsBenchmark < Minitest::Benchmark
  def bench_pathological_one
    assert_performance_linear(0.99) do |n|
      star = "*" * (n * 10)
      PathologicalInputs.markdown("#{star}#{star}hi#{star}#{star}")
    end
  end

  def bench_pathological_two
    assert_performance_linear(0.99) do |n|
      c = "`t`t`t`t`t`t" * (n * 10)
      PathologicalInputs.markdown(c)
    end
  end

  def bench_pathological_three
    assert_performance_linear(0.99) do |n|
      PathologicalInputs.markdown(" [a]: #{"A" * n}\n\n#{"[a][]" * n}\n")
    end
  end

  def bench_pathological_four
    assert_performance_linear(0.5) do |n|
      PathologicalInputs.markdown("#{"[" * n}a#{"]" * n}")
    end
  end

  def bench_pathological_five
    assert_performance_linear(0.99) do |n|
      PathologicalInputs.markdown("#{"**a *a " * n}#{"a* a**" * n}")
    end
  end

  def bench_unbound_recursion
    assert_performance_linear(0.99) do |n|
      PathologicalInputs.markdown("#{"[" * n}foo#{"](bar)" * n}")
    end
  end
end if ENV["BENCH"]
