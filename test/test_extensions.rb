require 'test_helper'

class TestExtensions < Minitest::Test
  def setup
    @markdown = <<-MD
One extension:

| a   | b   |
| --- | --- |
| c   | d   |

Another extension:

~~hi~~
    MD
  end

  def test_uses_specified_extensions
    none_in_use = CommonMarker.render_html(@markdown, :default, %i[])
    assert none_in_use.include?("| a")
    assert none_in_use.include?("~~hi~~")

    none_in_use = CommonMarker.render_html(@markdown, :default, %i[table])
    refute none_in_use.include?("| a")
    assert none_in_use.include?("~~hi~~")

    none_in_use = CommonMarker.render_html(@markdown, :default, %i[strikethrough])
    assert none_in_use.include?("| a")
    refute none_in_use.include?("~~hi~~")

    none_in_use = CommonMarker.render_html(@markdown, :default, %i[table strikethrough])
    refute none_in_use.include?("| a")
    refute none_in_use.include?("~~hi~~")
  end

  def test_bad_extension_specifications
    assert_raises(TypeError) { CommonMarker.render_html(@markdown, :default, "nope") }
    assert_raises(TypeError) { CommonMarker.render_html(@markdown, :default, ["table"]) }
    assert_raises(ArgumentError) { CommonMarker.render_html(@markdown, :default, %i[table bad]) }
  end
end
