# frozen_string_literal: true

require "test_helper"

class ConfigTest < Minitest::Test
  def test_config_merges_directly
    # hardbreaks work, the `\n` in between is rendered
    assert_equal("<p>aaaa<br />\nbbbb</p>\n", Commonmarker.to_html("aaaa\nbbbb"))

    # hardbreaks still work
    assert_equal("<p>aaaa<br />\nbbbb</p>\n", Commonmarker.to_html("aaaa\nbbbb", options: { render: { unsafe: false } }))
  end

  def test_same_config_again
    user_config = {
      extension: {
        header_ids: nil,
      },
    }

    text = "# Heading-1"
    expected = "<h1>Heading-1</h1>\n"

    assert_equal(expected, Commonmarker.to_html(text, options: user_config))

    # expect same result
    assert_equal(expected, Commonmarker.to_html(text, options: user_config))
  end

  def test_render_and_to_html_with_same_config
    user_config = {
      extension: {
        header_ids: nil,
      },
    }

    text = "# Heading-1"
    expected = "<h1>Heading-1</h1>\n"

    doc = Commonmarker.parse(text, options: user_config)
    # doc.walk do |node|
    #   # do something
    # end
    doc.to_html(options: user_config)

    assert_equal(expected, Commonmarker.to_html(text, options: user_config))
  end
end
