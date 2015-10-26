require 'ruby-enum'
module CommonMarker
  # For Ruby::Enum, these must be classes, not modules
  module Config

    class Parse
      include Ruby::Enum

      define :default, 0
      define :normalize, 4
      define :validate_utf8, 16
      define :safe, 32
    end

    class Render
      include Ruby::Enum

      define :default, 0
      define :sourcepos, 1
      define :hardbreaks, 2
      define :smart, 8
    end

    def self.process_options(option, type)
      type = Config.const_get(type.capitalize)
      if option.is_a?(Symbol)
        check_option(option, type)
        type.to_h[option]
      elsif option.is_a?(Array)
        option = [nil] if option.empty?
        # neckbearding around. the map will both check the opts and then bitwise-OR it
        option.map { |o| check_option(o, type); type.to_h[o] }.inject(0, :|)
      else
        fail TypeError, 'delimiter type must be a valid symbol or array of symbols'
      end
    end

    def self.check_option(option, type)
      unless type.keys.include?(option)
        fail TypeError, "option #{option} does not exist"
      end
    end
  end
end
