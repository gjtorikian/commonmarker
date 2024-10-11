# frozen_string_literal: true

require "test_helper"

class ConfigTest < Minitest::Test
  def test_process_options
    user_config = {
      parse: {
        smart: true,
      },
      render: {
        unsafe: false,
      },
    }
    processed_config = Commonmarker::Config.process_options(user_config)

    expected_config = [:parse, :render, :extension].each_with_object({}) do |type, hash|
      hash[type] = Commonmarker::Config::OPTIONS[type].merge(user_config[type] || {})
    end

    assert_equal(expected_config, processed_config)
  end

  def test_process_plugins
    user_config = {
      syntax_highlighter: {
        path: "./themes",
      },
    }
    processed_config = Commonmarker::Config.process_plugins(user_config)
    expected_config = [:syntax_highlighter].each_with_object({}) do |type, hash|
      hash[type] = Commonmarker::Config::PLUGINS[type].merge(user_config[type])
    end

    assert_equal(expected_config, processed_config)
  end

  def test_config_merges_directly
    # hardbreaks work, the `\n` in between is rendered
    assert_equal("<p>aaaa<br />\nbbbb</p>\n", Commonmarker.to_html("aaaa\nbbbb"))

    # hardbreaks still work
    assert_equal("<p>aaaa<br />\nbbbb</p>\n", Commonmarker.to_html("aaaa\nbbbb", options: { render: { unsafe: false } }))
  end
end
