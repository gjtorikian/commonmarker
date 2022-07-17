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

    def self.merged_with_defaults(options)
      Commonmarker::Config::OPTS.merge(process_options(options))
    end

    def self.process_options(options)
      {
        parse: process_parse_options(options[:parse]),
        render: process_render_options(options[:render]),
        extension: process_extension_options(options[:extension]),
      }
    end

    BOOLS = [true, false]
    ["parse", "render", "extension"].each do |type|
      define_singleton_method :"process_#{type}_options" do |options|
        Commonmarker::Config::OPTS[type.to_sym].each_with_object({}) do |(key, value), hash|
          hash[key] = value && next if options.nil? # option not provided, go for the default

          if options.nil? || options[key].nil? # option not provided, go for the defaul
            hash[key] = value
          else
            value_klass = value.class
            if value_klass.is_a?(TrueClass) || value_klass.is_a?(FalseClass)
              hash[key] = value if BOOLS.include?(value)
            else
              raise TypeError, "#{type}_options[:#{key}] must be a #{value.class}; got a #{options[key].class}" unless value.is_a?(value.class)

              hash[key] = options[key]
            end
          end
        end
      end
      # private :"process_#{type}_options"
    end
  end
end
