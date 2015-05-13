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

    def self.option_exists?(option)
      unless Config.keys.include?(option)
        fail StandardError, "option type does not exist #{option}"
      end
    end
  end
end
