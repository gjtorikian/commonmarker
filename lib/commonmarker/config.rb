# frozen_string_literal: true

module Commonmarker
  module Config
    # For details, see
    # https://github.com/kivikakk/comrak/blob/162ef9354deb2c9b4a4e05be495aa372ba5bb696/src/main.rs#L201
    OPTIONS = {
      parse: {
        smart: false,
        default_info_string: "",
      }.freeze,
      render: {
        hardbreaks: true,
        github_pre_lang: true,
        width: 80,
        unsafe: false,
        escape: false,
      }.freeze,
      extension: {
        strikethrough: true,
        tagfilter: true,
        table: true,
        autolink: true,
        tasklist: true,
        superscript: false,
        header_ids: "",
        footnotes: false,
        description_lists: false,
        front_matter_delimiter: nil,
        shortcodes: true,
      },
      format: [:html].freeze,
    }.freeze

    PLUGINS = {
      syntax_highlighter: {
        theme: "base16-ocean.dark",
        path: "",
      },
    }

    class << self
      include Commonmarker::Utils

      def merged_with_defaults(options)
        Commonmarker::Config::OPTIONS.merge(process_options(options))
      end

      def process_options(options)
        {
          parse: process_parse_options(options[:parse]),
          render: process_render_options(options[:render]),
          extension: process_extension_options(options[:extension]),
        }
      end

      def process_plugins(plugins)
        {
          syntax_highlighter: process_syntax_highlighter_plugin(plugins&.fetch(:syntax_highlighter, nil)),
        }
      end
    end

    [:parse, :render, :extension].each do |type|
      define_singleton_method :"process_#{type}_options" do |option|
        Commonmarker::Config::OPTIONS[type].each_with_object({}) do |(key, value), hash|
          if option.nil? # option not provided, go for the default
            hash[key] = value
            next
          end

          # option explicitly not included, remove it
          next if option[key].nil?

          hash[key] = fetch_kv(option, key, value, type)
        end
      end
    end

    [:syntax_highlighter].each do |type|
      define_singleton_method :"process_#{type}_plugin" do |plugin|
        return if plugin.nil? # plugin explicitly nil, remove it

        Commonmarker::Config::PLUGINS[type].each_with_object({}) do |(key, value), hash|
          if plugin.nil? # option not provided, go for the default
            hash[key] = value
            next
          end

          # option explicitly not included, remove it
          next if plugin[key].nil?

          hash[key] = fetch_kv(plugin, key, value, type)
        end
      end
    end
  end
end
