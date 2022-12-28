# frozen_string_literal: true

require "commonmarker/constants"

module Commonmarker
  module Utils
    include Commonmarker::Constants

    def fetch_kv(option, key, value, type)
      value_klass = value.class

      if Constants::BOOLS.include?(value) && BOOLS.include?(option[key])
        option[key]
      elsif option[key].is_a?(value_klass)
        option[key]
      else
        expected_type = Constants::BOOLS.include?(value) ? "Boolean" : value_klass.to_s
        raise TypeError, "#{type} option `:#{key}` must be #{expected_type}; got #{option[key].class}"
      end
    end
  end
end
