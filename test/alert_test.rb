# frozen_string_literal: true

require "test_helper"

class FrontmatterTest < Minitest::Test
  def test_renders_alert_notes
    md = "> [!note]\n> Something of note"

    expected = <<~HTML
      <blockquote>
      <p>[!note]
      Something of note</p>
      </blockquote>
    HTML

    # without extension
    assert_equal(expected, Commonmarker.to_html(md))

    expected = <<~HTML
      <div class="markdown-alert markdown-alert-note">
      <p class="markdown-alert-title">Note</p>
      <p>Something of note</p>
      </div>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { alerts: true } }))
  end

  def test_renders_alert_tip
    md = "> [!TIP]\n> Something of tip"

    expected = <<~HTML
      <blockquote>
      <p>[!TIP]
      Something of tip</p>
      </blockquote>
    HTML

    # without extension
    assert_equal(expected, Commonmarker.to_html(md))

    expected = <<~HTML
      <div class="markdown-alert markdown-alert-tip">
      <p class="markdown-alert-title">Tip</p>
      <p>Something of tip</p>
      </div>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { alerts: true } }))
  end

  def test_renders_alert_with_semantic_style
    md = "> [!note]\n> Something of note"

    expected = <<~HTML
      <aside class="admonition note">
      <p class="admonition-title">Note</p>
      <p>Something of note</p>
      </aside>
    HTML

    options = { extension: { alerts: true }, render: { alert_style: :semantic } }

    assert_equal(expected, Commonmarker.to_html(md, options: options))
  end

  def test_alert_style_must_be_a_symbol
    err = assert_raises(TypeError) { Commonmarker.to_html("x", options: { render: { alert_style: "semantic" } }) }
    assert_equal("render option `:alert_style` must be Symbol; got String", err.message)
  end

  def test_alert_style_rejects_unknown_names
    err = assert_raises(ArgumentError) { Commonmarker.to_html("x", options: { render: { alert_style: :fancy } }) }
    assert_equal("render option `:alert_style` must be one of :specific, :semantic; got :fancy", err.message)
  end

  def test_renders_a_complicated_node
    node = Commonmarker::Node.new(:alert, type: :warning, title: "This is bad")

    assert_equal(:alert, node.type)

    expected = <<~HTML
      <div class="markdown-alert markdown-alert-warning">
      <p class="markdown-alert-title">This is bad</p>
      </div>
    HTML
    assert_equal(expected, node.to_html)
  end
end
