require 'test_helper'
require 'minitest/benchmark' if ENV["BENCH"]

def markdown(s)
  Node.parse_string(s).to_html
end

# Disabled by default
# (these are the easy ones -- the evil ones are not disclosed)
if ENV["BENCH"] then
  class PathologicalInputsTest < Minitest::Benchmark
    def setup
    end

    def bench_pathological_1
      assert_performance_linear 0.99 do |n|
        star = '*'  * (n * 10)
        markdown("#{star}#{star}hi#{star}#{star}")
      end
    end

    def bench_pathological_2
      assert_performance_linear 0.99 do |n|
        c = "`t`t`t`t`t`t" * (n * 10)
        markdown(c)
      end
    end

    def bench_pathological_3
      assert_performance_linear 0.99 do |n|
        markdown(" [a]: #{ "A" * n }\n\n#{ "[a][]" * n }\n")
      end
    end

    def bench_pathological_4
      assert_performance_linear 0.5 do |n|
        markdown("#{'[' * n}a#{']' * n}")
      end
    end

    def bench_pathological_5
      assert_performance_linear 0.99 do |n|
        markdown("#{'**a *a ' * n}#{'a* a**' * n}")
      end
    end

    def bench_unbound_recursion
      assert_performance_linear 0.99 do |n|
        markdown(("[" * n) + "foo" + ("](bar)" * n ))
      end
    end
  end
end
