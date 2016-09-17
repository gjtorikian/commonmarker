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
    CommonMarker.render_html(@markdown, :default, %i[]).tap do |out|
      assert out.include?("| a")
      assert out.include?("| <strong>x</strong>")
      assert out.include?("~~hi~~")
    end

    CommonMarker.render_html(@markdown, :default, %i[table]).tap do |out|
      refute out.include?("| a")
      %w(<table> <tr> <th> a</th> <td> c</td> <strong>x</strong></td>).each {|html| assert out.include?(html) }
      assert out.include?("~~hi~~")
    end

    CommonMarker.render_html(@markdown, :default, %i[strikethrough]).tap do |out|
      assert out.include?("| a")
      refute out.include?("~~hi~~")
      assert out.include?("<del>hi</del>")
    end

    CommonMarker.render_html(@markdown, :default, %i[table strikethrough]).tap do |out|
      refute out.include?("| a")
      refute out.include?("| <strong>x</strong>")
      refute out.include?("~~hi~~")
    end
  end

  def test_bad_extension_specifications
    assert_raises(TypeError) { CommonMarker.render_html(@markdown, :default, "nope") }
    assert_raises(TypeError) { CommonMarker.render_html(@markdown, :default, ["table"]) }
    assert_raises(ArgumentError) { CommonMarker.render_html(@markdown, :default, %i[table bad]) }
  end
end
