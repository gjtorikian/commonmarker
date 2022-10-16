# frozen_string_literal: true

module Commonmarker
  module Config
    # For details, see
    # https://github.com/kivikakk/comrak/blob/162ef9354deb2c9b4a4e05be495aa372ba5bb696/src/main.rs#L201
    OPTS = {
      parse: {
        smart: false,
        default_info_string: "",
      }.freeze,
      render: {
        hardbreaks: true,
        github_pre_lang: true,
        width: 80,
        unsafe_: false,
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
        front_matter_delimiter: "",
      },
      format: [:html].freeze,
    }.freeze

    class << self
      def merged_with_defaults(options)
        Commonmarker::Config::OPTS.merge(process_options(options))
      end

      def process_options(options)
        {
          parse: process_parse_options(options[:parse]),
          render: process_render_options(options[:render]),
          extension: process_extension_options(options[:extension]),
        }
      end
    end

    BOOLS = [true, false]
    ["parse", "render", "extension"].each do |type|
      define_singleton_method :"process_#{type}_options" do |options|
        Commonmarker::Config::OPTS[type.to_sym].each_with_object({}) do |(key, value), hash|
          if options.nil? # option not provided, go for the default
            hash[key] = value
            next
          end

          # option explicitly not included, remove it
          next if options[key].nil?

          value_klass = value.class
          if BOOLS.include?(value) && BOOLS.include?(options[key])
            hash[key] = options[key]
          elsif options[key].is_a?(value_klass)
            hash[key] = options[key]
          else
            expected_type = BOOLS.include?(value) ? "Boolean" : value_klass.to_s
            raise TypeError, "#{type}_options[:#{key}] must be a #{expected_type}; got #{options[key].class}"
          end
        end
      end
    end
  end
end
