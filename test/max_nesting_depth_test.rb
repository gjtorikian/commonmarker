# frozen_string_literal: true

require "test_helper"

class MaxNestingDepthTest < Minitest::Test
  # block_quote (1) > paragraph (2) > text (3)
  SHALLOW = "> x"
  # block_quote (1) > block_quote (2) > paragraph (3) > text (4)
  DEEPER = "> > x"

  def test_default_is_a_parse_option
    assert_equal(1000, Commonmarker::Config::OPTIONS[:parse][:max_nesting_depth])
  end

  def test_default_limit_boundary
    assert_includes(Commonmarker.to_html("#{"> " * 998}x"), "<p>x</p>") # text sits at depth 1000
    assert_raises(Commonmarker::NestingDepthExceededError) { Commonmarker.to_html("#{"> " * 999}x") }
    assert_raises(Commonmarker::NestingDepthExceededError) { Commonmarker.parse("#{"> " * 999}x") }
  end

  def test_documents_up_to_the_limit_parse
    options = { parse: { max_nesting_depth: 3 } }

    assert_equal("<blockquote>\n<p>x</p>\n</blockquote>\n", Commonmarker.to_html(SHALLOW, options: options))
    assert_equal("<blockquote>\n<p>x</p>\n</blockquote>\n", Commonmarker.parse(SHALLOW, options: options).to_html)
  end

  def test_documents_past_the_limit_raise
    options = { parse: { max_nesting_depth: 3 } }

    err = assert_raises(Commonmarker::NestingDepthExceededError) { Commonmarker.to_html(DEEPER, options: options) }
    assert_equal("nesting depth exceeds the max_nesting_depth parse option (3)", err.message)

    err = assert_raises(Commonmarker::NestingDepthExceededError) { Commonmarker.parse(DEEPER, options: options) }
    assert_equal("nesting depth exceeds the max_nesting_depth parse option (3)", err.message)
  end

  def test_inline_nesting_counts
    # paragraph (1) > emph (2) > strong (3) > text (4)
    assert_raises(Commonmarker::NestingDepthExceededError) do
      Commonmarker.to_html("*a **b** c*", options: { parse: { max_nesting_depth: 3 } })
    end
  end

  def test_nil_restores_the_default
    assert_raises(Commonmarker::NestingDepthExceededError) do
      Commonmarker.to_html("#{"> " * 999}x", options: { parse: { max_nesting_depth: nil } })
    end
  end

  def test_rejects_non_integer_values
    err = assert_raises(TypeError) { Commonmarker.to_html(SHALLOW, options: { parse: { max_nesting_depth: "deep" } }) }
    assert_equal("parse option `:max_nesting_depth` must be Integer; got String", err.message)
  end

  def test_rejects_negative_values
    err = assert_raises(ArgumentError) { Commonmarker.to_html(SHALLOW, options: { parse: { max_nesting_depth: -1 } }) }
    assert_equal("parse option `:max_nesting_depth` must be a non-negative Integer; got -1", err.message)
  end

  def test_rendering_an_existing_tree_is_not_limited
    node = Commonmarker.parse(DEEPER)

    assert_includes(node.to_html(options: { parse: { max_nesting_depth: 1 } }), "<p>x</p>")
    assert_equal("> > x\n", node.to_commonmark(options: { parse: { max_nesting_depth: 1 } }))
  end
end
