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

    def self.process_options(option)
      if option.is_a?(Symbol)
        check_option(option)
        Config.to_h[option]
      elsif option.is_a?(Array)
        option = [nil] if option.empty?
        option.each { |delim| Config.check_option(delim) }
        return option.map { |delim| Config.to_h[delim] }.inject(0, :|)
      else
        fail TypeError, 'delimiter type must be a valid symbol or array of symbols'
      end
    end

    def self.check_option(option)
      unless Config.keys.include?(option)
        fail TypeError, "option type does not exist #{option}"
      end
    end
  end
end
