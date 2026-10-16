# frozen_string_literal: true

require "test_helper"

class MaliciousnessTest < Minitest::Test
  def test_rendering_with_bad_type
    assert_raises(TypeError) do
      Commonmarker.to_html(nil)
    end

    assert_raises(TypeError) do
      Commonmarker.to_html(123)
    end

    assert_raises(TypeError) do
      Commonmarker.to_html([123])
    end

    assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: 123)
    end

    assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: :totes_fake)
    end

    assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: [])
    end

    assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: [23])
    end

    assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: nil)
    end

    assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: [:SMART, "totes_fake"])
    end
  end

  def test_bad_options_value
    err = assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz", options: { parse: { smart: 111 } })
    end

    assert_equal("parse option `:smart` must be Boolean; got Integer", err.message)
  end

  def test_bad_extension_type
    assert_raises(TypeError) { Commonmarker.to_html(@markdown, options: { extensions: "nope" }) }
  end

  def test_non_utf8
    err = assert_raises(TypeError) do
      Commonmarker.to_html("foo \n baz".encode("US-ASCII"))
    end

    assert_equal("text must be UTF-8 encoded; got US-ASCII!", err.message)
  end

  def test_gc_stress_test
    GC.stress = true

    text = "Hello **world** -- how are _you_ today? I'm ~~fine~~, ~yourself~?"

    html = Commonmarker.to_html(text, options: Commonmarker::Config::OPTIONS).rstrip

    # If this segfaults, then it failed the test
    assert_equal("<p>Hello <strong>world</strong> -- how are <em>you</em> today? I'm <del>fine</del>, <del>yourself</del>?</p>", html)
    GC.stress = false
  end

  # GHSA-c4fj-h48v-9fxp: copying the parse tree to and from the Ruby-visible
  # tree used to recurse once per level of nesting, so deeply nested input
  # overflowed the native stack and took the whole process down.
  DEEPLY_NESTED = "#{"> " * 100_000}x\n".freeze

  def test_deeply_nested_input_is_rejected_by_default
    assert_raises(Commonmarker::NestingDepthExceededError) { Commonmarker.parse(DEEPLY_NESTED) }
    assert_raises(Commonmarker::NestingDepthExceededError) { Commonmarker.to_html(DEEPLY_NESTED) }
  end

  # With the limit lifted, every path must still cope without recursing. This
  # runs in a thread because a thread's native stack is smaller than the main
  # thread's, which keeps the test strict on every platform.
  def test_deeply_nested_input_does_not_overflow_the_native_stack
    depth = 100_000
    options = { parse: { max_nesting_depth: depth + 10 } }

    html, commonmark, direct_html, walked = Thread.new do # rubocop:disable ThreadSafety/NewThread
      node = Commonmarker.parse(DEEPLY_NESTED, options: options)
      [node.to_html, node.to_commonmark, Commonmarker.to_html(DEEPLY_NESTED, options: options), node.walk.count]
    end.value

    assert_equal(depth, html.scan("<blockquote>").count)
    assert_includes(html, "<p>x</p>")
    assert_equal("#{"> " * depth}x\n", commonmark)
    assert_equal(html, direct_html)
    assert_equal(depth + 3, walked) # document, the blockquotes, paragraph, text
  end

  # Freeing the Ruby-visible tree used to recurse once per nesting level as
  # well, but only for trees whose nested node is not a first child, such as
  # nested emphasis. See note above re: ThreadSafety and native stack limits.
  def test_freeing_a_deeply_nested_tree_does_not_overflow_the_native_stack
    doc = "#{"*a **a " * 65_000}b#{" a** a*" * 65_000}"
    options = { parse: { max_nesting_depth: 200_000 } }

    collected = Thread.new do # rubocop:disable ThreadSafety/NewThread
      trees = ObjectSpace::WeakMap.new
      # Ruby scans the native stack conservatively, so a stale stack slot can
      # pin a tree (usually the most recent one) and keep it from ever being
      # collected. Build several, each in its own frame, and require only that
      # at least one is freed, which is enough to exercise the teardown.
      build = -> { trees[Commonmarker.parse(doc, options: options)] = true }
      3.times { build.call }
      (1..10).any? do
        GC.start
        trees.size < 3
      end
    end.value

    assert(collected, "no tree was ever garbage collected, so teardown was not exercised")
  end
end
