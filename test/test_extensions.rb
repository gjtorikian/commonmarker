# frozen_string_literal: true

require "test_helper"

class TestExtensions < Minitest::Test
  def setup
    @markdown = fixtures_file("table.md")
  end

  def test_uses_specified_extensions
    Commonmarker.to_html(@markdown, options: { extension: {} }).tap do |out|
      assert_includes(out, "| a")
      assert_includes(out, "| <strong>x</strong>")
      assert_includes(out, "~~hi~~")
    end

    Commonmarker.to_html(@markdown, options: { extension: { table: true } }).tap do |out|
      refute_includes(out, "| a")
      ["<table>", "<tr>", "<th>", "a", "</th>", "<td>", "c", "</td>", "<strong>x</strong>"].each { |html| assert_includes(out, html) }
      assert_includes(out, "~~hi~~")
    end

    Commonmarker.to_html(@markdown, options: { extension: { strikethrough: true } }).tap do |out|
      assert_includes(out, "| a")
      refute_includes(out, "~~hi~~")
      assert_includes(out, "<del>hi</del>")
    end
  end

  def test_bad_extension_specifications
    assert_raises(TypeError) { Commonmarker.to_html(@markdown, options: "nope") }
  end

  def test_comments_are_kept_as_expected
    options = { render: { unsafe_: true }, extension: { tagfilter: true } }
    assert_equal("<!--hello--> <blah> &lt;xmp>\n",
      Commonmarker.to_html("<!--hello--> <blah> <xmp>\n", options: options))
  end
end
