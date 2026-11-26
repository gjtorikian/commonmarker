# frozen_string_literal: true

require "test_helper"

class RenderOptionsTest < Minitest::Test
  def test_list_style_changes_the_bullet_marker
    doc = Commonmarker.parse("- one\n- two\n")

    assert_equal("- one\n- two\n", doc.to_commonmark)
    assert_equal("+ one\n+ two\n", doc.to_commonmark(options: { render: { list_style: :plus } }))
    assert_equal("* one\n* two\n", doc.to_commonmark(options: { render: { list_style: :star } }))
    assert_equal("- one\n- two\n", doc.to_commonmark(options: { render: { list_style: :dash } }))
  end

  def test_list_style_accepts_strings_too
    doc = Commonmarker.parse("- one\n- two\n")

    assert_equal("+ one\n+ two\n", doc.to_commonmark(options: { render: { list_style: "plus" } }))
    assert_equal("* one\n* two\n", doc.to_commonmark(options: { render: { list_style: "star" } }))
  end

  def test_list_style_must_be_a_string_or_symbol
    err = assert_raises(TypeError) { Commonmarker.to_html("- one", options: { render: { list_style: 1 } }) }
    assert_equal("render option `:list_style` must be a String or Symbol; got Integer", err.message)
  end

  def test_list_style_rejects_unknown_names
    err = assert_raises(ArgumentError) { Commonmarker.to_html("- one", options: { render: { list_style: :bullet } }) }
    assert_equal("render option `:list_style` must be one of :dash, :plus, :star; got \"bullet\"", err.message)

    err = assert_raises(ArgumentError) { Commonmarker.to_html("- one", options: { render: { list_style: "bullet" } }) }
    assert_equal("render option `:list_style` must be one of :dash, :plus, :star; got \"bullet\"", err.message)
  end

  def test_list_style_nil_keeps_the_default
    doc = Commonmarker.parse("- one\n")

    assert_equal("- one\n", doc.to_commonmark(options: { render: { list_style: nil } }))
  end

  def test_ol_width_pads_ordered_list_markers
    doc = Commonmarker.parse("1. Something\n")

    assert_equal("1. Something\n", doc.to_commonmark)
    assert_equal("1.   Something\n", doc.to_commonmark(options: { render: { ol_width: 5 } }))
  end

  def test_ol_width_must_be_non_negative
    err = assert_raises(ArgumentError) { Commonmarker.to_html("1. x", options: { render: { ol_width: -1 } }) }
    assert_equal("render option `:ol_width` must be a non-negative Integer; got -1", err.message)
  end

  def test_experimental_minimize_commonmark_drops_needless_escapes
    doc = Commonmarker.parse("__hi\n")

    assert_equal("\\_\\_hi\n", doc.to_commonmark)
    assert_equal("__hi\n", doc.to_commonmark(options: { render: { experimental_minimize_commonmark: true } }))
  end

  def test_figure_with_caption
    md = <<~MARKDOWN
      ![image](https://example.com/i.png "this is an image")
    MARKDOWN
    expected = <<~HTML
      <p><figure><img src="https://example.com/i.png" alt="image" title="this is an image" /><figcaption>this is an image</figcaption></figure></p>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { render: { figure_with_caption: true } }))
  end
end
