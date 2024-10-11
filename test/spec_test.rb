# frozen_string_literal: true

require "test_helper"
require "json"

class SpecTest < Minitest::Test
  spec = load_spec_file("spec.txt")

  spec.each do |testcase|
    define_method(:"test_to_html_example_#{testcase[:example]}") do
      render_options = Commonmarker::Config::OPTIONS[:render].each_with_object({}) do |(key, _value), hsh|
        hsh[key] = nil
      end
      render_options[:unsafe] = true
      render_options[:gfm_quirks] = true

      string_extensions = [:front_matter_delimiter, :header_ids]
      extensions_options = Commonmarker::Config::OPTIONS[:extension].each_with_object({}) do |(key, _value), hsh|
        hsh[key] = if string_extensions.include?(key)
          nil
        else
          false
        end
      end

      testcase[:extensions].each do |ext, _value|
        extensions_options[ext] = true
      end

      options = {
        render: render_options,
        extension: extensions_options,
      }

      options[:extension][:tasklist] = true
      actual = Commonmarker.to_html(testcase[:markdown], options: options, plugins: nil).rstrip

      assert_equal testcase[:html], actual, testcase[:markdown]
    end
  end
end
