require 'ruby-enum'

module CommonMarker
  # For Ruby::Enum, this must be a class, not a module
  class Config
    include Ruby::Enum

    define :default, 0
    define :sourcepos, 1
    define :hardbreaks, 2
    define :normalize, 4
    define :smart, 8
    define :validate_utf8, 16
    define :safe, 32

    def self.process_options(option)
      if option.is_a?(Symbol)
        check_option(option)
        Config.to_h[option]
      elsif option.is_a?(Array)
        option = [nil] if option.empty?
        # neckbearding around. the map will both check the opts and then bitwise-OR it
        option.map { |o| Config.check_option(o); Config.to_h[o] }.inject(0, :|)
      else
        fail TypeError, 'delimiter type must be a valid symbol or array of symbols'
      end
    end

    def self.check_option(option)
      unless Config.keys.include?(option)
        fail TypeError, "option #{option} does not exist"
      end
    end
  end
end
