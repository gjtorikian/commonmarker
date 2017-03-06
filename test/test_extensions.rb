require 'test_helper'

class TestExtensions < Minitest::Test
  def setup
    @markdown = <<-MD
One extension:

| a   | b   |
| --- | --- |
| c   | d   |
| **x** | |

Another extension:

~~hi~~
    MD
  end

  def test_uses_specified_extensions
    CommonMarker.render_html(@markdown, :DEFAULT, %i[]).tap do |out|
      assert out.include?("| a")
      assert out.include?("| <strong>x</strong>")
      assert out.include?("~~hi~~")
    end

    CommonMarker.render_html(@markdown, :DEFAULT, %i[table]).tap do |out|
      refute out.include?("| a")
      %w(<table> <tr> <th> a </th> <td> c </td> <strong>x</strong>).each {|html| assert out.include?(html) }
      assert out.include?("~~hi~~")
    end

    CommonMarker.render_html(@markdown, :DEFAULT, %i[strikethrough]).tap do |out|
      assert out.include?("| a")
      refute out.include?("~~hi~~")
      assert out.include?("<del>hi</del>")
    end

    CommonMarker.render_html(@markdown, :DEFAULT, %i[table strikethrough]).tap do |out|
      refute out.include?("| a")
      refute out.include?("| <strong>x</strong>")
      refute out.include?("~~hi~~")
    end

  end

  def test_extensions_with_renderers
    doc = CommonMarker.render_doc(@markdown, :DEFAULT, %i[table])

    doc.to_html.tap do |out|
      refute out.include?("| a")
      %w(<table> <tr> <th> a </th> <td> c </td> <strong>x</strong>).each {|html| assert out.include?(html) }
      assert out.include?("~~hi~~")
    end

    HtmlRenderer.new.render(doc).tap do |out|
      refute out.include?("| a")
      %w(<table> <tr> <th> a </th> <td> c </td> <strong>x</strong>).each {|html| assert out.include?(html) }
      assert out.include?("~~hi~~")
    end
  end

  def test_bad_extension_specifications
    assert_raises(TypeError) { CommonMarker.render_html(@markdown, :DEFAULT, "nope") }
    assert_raises(TypeError) { CommonMarker.render_html(@markdown, :DEFAULT, ["table"]) }
    assert_raises(ArgumentError) { CommonMarker.render_html(@markdown, :DEFAULT, %i[table bad]) }
  end

  def test_comments_are_kept_as_expected
    assert_equal "<!--hello--> <blah> &lt;xmp>\n",
      CommonMarker.render_html("<!--hello--> <blah> <xmp>\n", :DEFAULT, %i[tagfilter])
  end
end
