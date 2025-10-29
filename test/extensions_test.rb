# frozen_string_literal: true

require "test_helper"

class ExtensionsTest < Minitest::Test
  def setup
    @markdown = fixtures_file("table.md")
  end

  def test_uses_specified_extensions
    Commonmarker.to_html(@markdown, options: { extension: { table: false, strikethrough: false } }).tap do |out|
      assert_includes(out, "| a")
      assert_includes(out, "| <strong>x</strong>")
      assert_includes(out, "~~hi~~")
    end

    Commonmarker.to_html(@markdown, options: { extension: { table: true, strikethrough: false } }).tap do |out|
      refute_includes(out, "| a")
      ["<table>", "<tr>", "<th>", "a", "</th>", "<td>", "c", "</td>", "<strong>x</strong>"].each { |html| assert_includes(out, html) }

      assert_includes(out, "~~hi~~")
    end

    Commonmarker.to_html(@markdown, options: { extension: { table: false, strikethrough: true } }).tap do |out|
      assert_includes(out, "| a")
      refute_includes(out, "~~hi~~")
      assert_includes(out, "<del>hi</del>")
    end
  end

  def test_comments_are_kept_as_expected
    options = { render: { unsafe: true }, extension: { tagfilter: true } }

    assert_equal(
      "<!--hello--> <blah> &lt;xmp>\n",
      Commonmarker.to_html("<!--hello--> <blah> <xmp>\n", options: options),
    )
  end

  def test_definition_lists
    markdown = <<~MARKDOWN
      Commonmark Definition

      : Ruby wrapper for comrak (CommonMark parser)
    MARKDOWN

    extensions = { description_lists: true }
    options = { extension: extensions, render: { hardbreaks: false } }
    output = Commonmarker.to_html(markdown, options: options)

    html = <<~HTML
      <dl>
      <dt>Commonmark Definition</dt>
      <dd>
      <p>Ruby wrapper for comrak (CommonMark parser)</p>
      </dd>
      </dl>
    HTML
    assert_equal(output, html)
  end

  def test_emoji_renders_by_default
    assert_equal(
      "<p>Happy Friday! 😄</p>\n",
      Commonmarker.to_html("Happy Friday! :smile:"),
    )
  end

  def test_can_disable_emoji_renders
    options = { extension: { shortcodes: false } }

    assert_equal(
      "<p>Happy Friday! :smile:</p>\n",
      Commonmarker.to_html("Happy Friday! :smile:", options: options),
    )
  end

  def test_subscript_disabled_by_default
    assert_equal(
      "<p><del>H<del>2</del>O</del></p>\n",
      Commonmarker.to_html("~~H~2~O~~"),
    )
  end

  def test_can_support_subscript
    options = { extension: { subscript: true } }

    assert_equal(
      "<p><del>H<sub>2</sub>O</del></p>\n",
      Commonmarker.to_html("~~H~2~O~~", options: options),
    )
  end

  def test_can_support_subtext
    options = { extension: { subtext: true } }

    assert_equal(
      "<p><sub>subtext</sub></p>\n",
      Commonmarker.to_html("-# subtext", options: options),
    )
  end

  def test_cjk_friendly_emphasis
    assert_equal(
      "<p>**この文は重要です。**但这句话并不重要。</p>\n",
      Commonmarker.to_html("**この文は重要です。**但这句话并不重要。"),
    )

    options = { extension: { cjk_friendly_emphasis: true } }

    assert_equal(
      "<p><strong>この文は重要です。</strong>但这句话并不重要。</p>\n",
      Commonmarker.to_html("**この文は重要です。**但这句话并不重要。", options: options),
    )
  end
end
