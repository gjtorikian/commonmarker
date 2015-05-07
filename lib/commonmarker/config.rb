require 'ruby-enum'

module CommonMarker
  class Config
    include Ruby::Enum

    define :default, 0
    define :sourcepos, 1
    define :hardbreaks, 2
    define :normalize, 4
    define :smart, 8

  end
end
