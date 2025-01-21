# frozen_string_literal: true

require "test_helper"

class FrontmatterTest < Minitest::Test
  def test_renders_alert_notes
    md = "> [!note]\n> Something of note"

    expected = <<~HTML
      <blockquote>
      <p>[!note]<br />
      Something of note</p>
      </blockquote>
    HTML

    # without extension
    assert_equal(expected, Commonmarker.to_html(md))

    expected = <<~HTML
      <div class="alert alert-note">
      <p class="alert-title">Note</p>
      <p>Something of note</p>
      </div>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { alerts: true } }))
  end

  def test_renders_alert_tip
    md = "> [!TIP]\n> Something of tip"

    expected = <<~HTML
      <blockquote>
      <p>[!TIP]<br />
      Something of tip</p>
      </blockquote>
    HTML

    # without extension
    assert_equal(expected, Commonmarker.to_html(md))

    expected = <<~HTML
      <div class="alert alert-tip">
      <p class="alert-title">Tip</p>
      <p>Something of tip</p>
      </div>
    HTML

    assert_equal(expected, Commonmarker.to_html(md, options: { extension: { alerts: true } }))
  end

  def test_renders_a_complicated_node
    node = Commonmarker::Node.new(:alert, type: :warning, title: "This is bad")

    assert_equal(:alert, node.type)

    expected = <<~HTML
      <div class="alert alert-warning">
      <p class="alert-title">This is bad</p>
      </div>
    HTML
    assert_equal(expected, node.to_html)
  end
end
