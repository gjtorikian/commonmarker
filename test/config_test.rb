# frozen_string_literal: true

require "test_helper"

class ConfigTest < Minitest::Test
  def test_defaults_are_comraks
    # soft line breaks stay soft, as in CommonMark
    assert_equal("<p>aaaa\nbbbb</p>\n", Commonmarker.to_html("aaaa\nbbbb"))

    # options apply over the defaults
    assert_equal("<p>aaaa<br />\nbbbb</p>\n", Commonmarker.to_html("aaaa\nbbbb", options: { render: { hardbreaks: true } }))

    # an unrelated option leaves the rest at their defaults
    assert_equal("<p>aaaa\nbbbb</p>\n", Commonmarker.to_html("aaaa\nbbbb", options: { render: { unsafe: false } }))
  end

  def test_no_extensions_or_plugins_by_default
    assert_equal("<p>~~hi~~ :smile: www.example.com</p>\n", Commonmarker.to_html("~~hi~~ :smile: www.example.com"))
    assert_equal("<h1>Heading</h1>\n", Commonmarker.to_html("# Heading"))
    assert_equal("<pre><code class=\"language-ruby\">puts 1\n</code></pre>\n", Commonmarker.to_html("```ruby\nputs 1\n```"))
  end

  def test_nil_means_the_default
    text = "# Heading\n\naaaa\nbbbb"
    options = { render: { hardbreaks: nil, width: nil }, extension: { header_ids: nil, table: nil } }

    assert_equal(Commonmarker.to_html(text), Commonmarker.to_html(text, options: options))
  end

  def test_passing_the_defaults_back_changes_nothing
    text = "# Heading\n\nHello **world** -- how are _you_ today? I'm ~~fine~~\nand *you*?"

    assert_equal(
      Commonmarker.to_html(text),
      Commonmarker.to_html(text, options: Commonmarker::Config::OPTIONS, plugins: Commonmarker::Config::PLUGINS),
    )
  end

  def test_exposes_defaults
    options = Commonmarker::Config::OPTIONS

    assert_nil(options[:parse][:default_info_string])
    refute(options[:render][:hardbreaks])
    refute(options[:render][:github_pre_lang])
    refute(options[:render][:escaped_char_spans])
    assert_equal(0, options[:render][:width])
    refute(options[:extension][:strikethrough])
    refute(options[:extension][:table])
    refute(options[:extension][:autolink])
    refute(options[:extension][:tasklist])
    refute(options[:extension][:shortcodes])
    assert_nil(options[:extension][:header_ids])
    assert_nil(options[:extension][:front_matter_delimiter])

    assert_equal({ syntax_highlighter: nil }, Commonmarker::Config::PLUGINS)
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

  def test_exposes_new_comrak_options_with_defaults
    options = Commonmarker::Config::OPTIONS

    refute(options[:parse][:tasklist_in_table])
    assert_equal(:dash, options[:render][:list_style])
    assert_equal(:specific, options[:render][:alert_style])
    assert_equal(0, options[:render][:ol_width])
    refute(options[:extension][:ofm_callouts])
  end
end
